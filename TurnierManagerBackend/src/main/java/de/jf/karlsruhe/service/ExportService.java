package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.dto.*;
import de.jf.karlsruhe.model.enums.GameStatus;
import de.jf.karlsruhe.model.enums.ScheduledItemType;
import de.jf.karlsruhe.model.repos.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.atomic.AtomicLong;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ExportService {

    private final TournamentRepository tournamentRepository;
    private final AgeGroupRepository ageGroupRepository;
    private final ScheduledItemRepository scheduledItemRepository;
    private final ScheduledGameRepository scheduledGameRepository;
    private final ScheduledBreakRepository scheduledBreakRepository;

    private static final ZoneId ZONE = ZoneId.of("Europe/Berlin");
    private static final DateTimeFormatter ISO_FORMATTER = DateTimeFormatter.ISO_OFFSET_DATE_TIME;
    private static final Pattern NUMBER_PATTERN = Pattern.compile("(\\d+)");

    @Transactional(readOnly = true)
    public ExportTournamentDTO exportTournament() {
        List<Tournament> tournaments = tournamentRepository.findAll();
        if (tournaments.isEmpty()) {
            return null;
        }

        Tournament tournament = tournaments.getFirst();
        List<AgeGroup> ageGroups = ageGroupRepository.findAll();

        List<ExportAgeGroupRefDTO> ageGroupRefs = ageGroups.stream()
                .map(ag -> new ExportAgeGroupRefDTO(
                        ag.getName().toLowerCase(),
                        ag.getName(),
                        "data/" + ag.getName().toLowerCase() + ".json"
                ))
                .toList();

        return new ExportTournamentDTO(
                tournament.getName(),
                formatNow(),
                ageGroupRefs
        );
    }

    @Transactional(readOnly = true)
    public ExportAgeGroupDTO exportAgeGroup(String slug) {
        AgeGroup ageGroup = ageGroupRepository.findAll().stream()
                .filter(ag -> ag.getName().equalsIgnoreCase(slug))
                .findFirst()
                .orElse(null);

        if (ageGroup == null) {
            return null;
        }

        // Alle ScheduleItems fuer diese Altersgruppe, sortiert nach Startzeit
        List<ScheduleItem> items = scheduledItemRepository.findByAgeGroupOrderByStartTimeAsc(ageGroup);

        if (items.isEmpty()) {
            return new ExportAgeGroupDTO(ageGroup.getName(), formatNow(), List.of(), List.of());
        }

        // Spiele und Pausen separat filtern
        List<ScheduleItem> gameItems = items.stream()
                .filter(item -> ScheduledItemType.GAME.equals(item.getItemType()))
                .toList();

        List<ScheduleItem> breakItems = items.stream()
                .filter(item -> ScheduledItemType.BREAK.equals(item.getItemType()))
                .toList();

        // Spiele mappen
        Map<ScheduleItem, ScheduledGame> gameMap = scheduledGameRepository.findByScheduleItemIn(gameItems).stream()
                .collect(Collectors.toMap(ScheduledGame::getScheduleItem, game -> game));

        List<ExportMatchDTO> matches = gameItems.stream()
                .map(item -> mapToMatch(item, gameMap.get(item)))
                .filter(Objects::nonNull)
                .toList();

        // Pausen mappen (echte ScheduledBreak-Entitaeten)
        AtomicLong pauseId = new AtomicLong(1);
        List<ExportPauseDTO> pauseTimes = breakItems.stream()
                .map(item -> mapToBreak(item, pauseId))
                .toList();

        return new ExportAgeGroupDTO(ageGroup.getName(), formatNow(), matches, pauseTimes);
    }

    // ---- Mapping ----

    private ExportMatchDTO mapToMatch(ScheduleItem item, ScheduledGame game) {
        if (game == null) {
            return null;
        }

        String status = deriveStatus(item.getStatus());
        Integer scoreA = "scheduled".equals(status) ? null : game.getTeamAScore();
        Integer scoreB = "scheduled".equals(status) ? null : game.getTeamBScore();

        return new ExportMatchDTO(
                game.getGameNumber(),
                formatLocalDateTime(item.getStartTime()),
                pitchToField(item.getScheduledPitch()),
                game.getTeamA() != null ? game.getTeamA().getName() : "???",
                game.getTeamB() != null ? game.getTeamB().getName() : "???",
                status,
                scoreA,
                scoreB
        );
    }

    private ExportPauseDTO mapToBreak(ScheduleItem item, AtomicLong pauseId) {
        String message = scheduledBreakRepository.findByScheduleItem(item)
                .map(ScheduledBreak::getMessage)
                .orElse("Pause");

        return new ExportPauseDTO(
                pauseId.getAndIncrement(),
                formatLocalDateTime(item.getStartTime()),
                formatLocalDateTime(item.getEndTime()),
                pitchToField(item.getScheduledPitch()),
                message
        );
    }

    private String deriveStatus(GameStatus status) {
        if (status == null) {
            return "scheduled";
        }
        return switch (status) {
            case COMPLETED, COMPLETED_AND_STATED -> "completed";
            case IN_PROGRESS -> "live";
            case CANCELED -> "canceled";
            default -> "scheduled";
        };
    }

    private Object pitchToField(Pitch pitch) {
        if (pitch == null) return null;
        Matcher m = NUMBER_PATTERN.matcher(pitch.getName());
        if (m.find()) {
            return Integer.parseInt(m.group(1));
        }
        return pitch.getName();
    }

    private String formatLocalDateTime(java.time.LocalDateTime ldt) {
        if (ldt == null) return null;
        return ldt.atZone(ZONE).format(ISO_FORMATTER);
    }

    private String formatNow() {
        return OffsetDateTime.now(ZONE).format(ISO_FORMATTER);
    }
}
