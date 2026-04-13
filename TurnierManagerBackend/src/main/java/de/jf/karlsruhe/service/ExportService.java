package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.dto.*;
import de.jf.karlsruhe.model.enums.GameStatus;
import de.jf.karlsruhe.model.enums.ScheduledItemType;
import de.jf.karlsruhe.model.repos.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ExportService {

    private final TournamentRepository tournamentRepository;
    private final AgeGroupRepository ageGroupRepository;
    private final ScheduledGameRepository scheduledGameRepository;
    private final ScheduledItemRepository scheduledItemRepository;
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

        // Alle ScheduleItems fuer diese Altersgruppe
        List<ScheduleItem> items = scheduledItemRepository.findByAgeGroupOrderByStartTimeAsc(ageGroup);

        if (items.isEmpty()) {
            return new ExportAgeGroupDTO(ageGroup.getName(), formatNow(), List.of(), List.of());
        }

        // Spiel-Items filtern
        List<ScheduleItem> gameItems = items.stream()
                .filter(si -> si.getItemType() == ScheduledItemType.GAME)
                .toList();

        // ScheduledGames fuer die Spiel-Items laden
        List<ScheduledGame> games = scheduledGameRepository.findByScheduleItemIn(gameItems);

        // Nach Startzeit sortieren
        games.sort(Comparator.comparing(g -> g.getScheduleItem().getStartTime()));

        List<ExportMatchDTO> matches = games.stream()
                .map(this::mapGameToMatch)
                .toList();

        // Pausen erkennen (Break-Items)
        List<ScheduleItem> breakItems = items.stream()
                .filter(si -> si.getItemType() == ScheduledItemType.BREAK)
                .toList();

        List<ExportPauseDTO> pauses = mapBreaks(breakItems);

        return new ExportAgeGroupDTO(ageGroup.getName(), formatNow(), matches, pauses);
    }

    // ---- Interne Hilfsmethoden ----

    private ExportMatchDTO mapGameToMatch(ScheduledGame game) {
        ScheduleItem item = game.getScheduleItem();
        String status = deriveStatus(item);
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

    private String deriveStatus(ScheduleItem item) {
        GameStatus gs = item.getStatus();
        if (gs == null) {
            return "scheduled";
        }
        return switch (gs) {
            case COMPLETED, COMPLETED_AND_STATED -> "completed";
            case IN_PROGRESS -> "live";
            case CANCELED -> "canceled";
            default -> "scheduled";
        };
    }

    private List<ExportPauseDTO> mapBreaks(List<ScheduleItem> breakItems) {
        List<ExportPauseDTO> pauses = new ArrayList<>();
        long pauseId = 1;

        for (ScheduleItem item : breakItems) {
            // Pausen-Nachricht aus ScheduledBreak laden
            String message = scheduledBreakRepository.findByScheduleItem(item)
                    .map(ScheduledBreak::getMessage)
                    .orElse("Pause");

            pauses.add(new ExportPauseDTO(
                    pauseId++,
                    formatLocalDateTime(item.getStartTime()),
                    formatLocalDateTime(item.getEndTime()),
                    pitchToField(item.getScheduledPitch()),
                    message
            ));
        }

        pauses.sort(Comparator.comparing(ExportPauseDTO::getStartTime));
        return pauses;
    }

    private Object pitchToField(Pitch pitch) {
        if (pitch == null) return null;
        Matcher m = NUMBER_PATTERN.matcher(pitch.getName());
        if (m.find()) {
            return Integer.parseInt(m.group(1));
        }
        return pitch.getName();
    }

    private String formatLocalDateTime(LocalDateTime ldt) {
        if (ldt == null) return null;
        return ldt.atZone(ZONE).format(ISO_FORMATTER);
    }

    private String formatNow() {
        return OffsetDateTime.now(ZONE).format(ISO_FORMATTER);
    }
}
