package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.dto.*;
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
    private final GameRepository gameRepository;
    private final RoundRepository roundRepository;

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

        // Alle Runden fuer diese Altersgruppe
        List<Round> rounds = roundRepository.findAll().stream()
                .filter(r -> r.getLeagues() != null && r.getLeagues().stream()
                        .anyMatch(l -> l.getAgeGroup() != null
                                && Objects.equals(l.getAgeGroup().getId(), ageGroup.getId())))
                .toList();

        if (rounds.isEmpty()) {
            return new ExportAgeGroupDTO(ageGroup.getName(), formatNow(), List.of(), List.of());
        }

        List<Game> allGames = gameRepository.findByRounds(rounds);

        // Spiele filtern die zu dieser Altersgruppe gehoeren
        List<Game> ageGroupGames = allGames.stream()
                .filter(game -> belongsToAgeGroup(game, ageGroup))
                .sorted(Comparator.comparing(Game::getStartTime))
                .toList();

        List<ExportMatchDTO> matches = ageGroupGames.stream()
                .map(this::mapGameToMatch)
                .toList();

        List<ExportPauseDTO> pauseTimes = detectPauses(ageGroupGames, rounds.getFirst().getTournament());

        return new ExportAgeGroupDTO(ageGroup.getName(), formatNow(), matches, pauseTimes);
    }

    // ---- Interne Hilfsmethoden ----

    private boolean belongsToAgeGroup(Game game, AgeGroup ageGroup) {
        if (game.getLeague() != null && game.getLeague().getAgeGroup() != null) {
            return Objects.equals(game.getLeague().getAgeGroup().getId(), ageGroup.getId());
        }
        if (game.getRound() != null && game.getRound().getLeagues() != null) {
            return game.getRound().getLeagues().stream()
                    .filter(league -> league.getAgeGroup() != null
                            && Objects.equals(league.getAgeGroup().getId(), ageGroup.getId()))
                    .anyMatch(league -> league.getTeams() != null
                            && (league.getTeams().contains(game.getTeamA())
                            || league.getTeams().contains(game.getTeamB())));
        }
        return false;
    }

    private ExportMatchDTO mapGameToMatch(Game game) {
        String status = deriveStatus(game);
        Integer scoreA = "scheduled".equals(status) ? null : game.getTeamAScore();
        Integer scoreB = "scheduled".equals(status) ? null : game.getTeamBScore();

        return new ExportMatchDTO(
                game.getGameNumber(),
                formatLocalDateTime(game.getStartTime()),
                pitchToField(game.getPitch()),
                game.getTeamA() != null ? game.getTeamA().getName() : "???",
                game.getTeamB() != null ? game.getTeamB().getName() : "???",
                status,
                scoreA,
                scoreB
        );
    }

    private String deriveStatus(Game game) {
        if (game.getActualStartTime() != null && game.getActualEndTime() != null) {
            return "completed";
        } else if (game.getActualStartTime() != null) {
            return "live";
        } else {
            return "scheduled";
        }
    }

    private List<ExportPauseDTO> detectPauses(List<Game> games, Tournament tournament) {
        if (games.isEmpty() || tournament == null || tournament.getGameSettings() == null) {
            return List.of();
        }

        GameSettings gs = tournament.getGameSettings();
        int playTime = gs.getPlayTime();
        int breakTime = gs.getBreakTime();

        // Spiele pro Feld gruppieren
        Map<Pitch, List<Game>> gamesByPitch = games.stream()
                .filter(g -> g.getPitch() != null)
                .collect(Collectors.groupingBy(Game::getPitch));

        List<ExportPauseDTO> pauses = new ArrayList<>();
        long pauseId = 1;

        for (Map.Entry<Pitch, List<Game>> entry : gamesByPitch.entrySet()) {
            Pitch pitch = entry.getKey();
            List<Game> pitchGames = entry.getValue().stream()
                    .sorted(Comparator.comparing(Game::getStartTime))
                    .toList();

            for (int i = 0; i < pitchGames.size() - 1; i++) {
                Game current = pitchGames.get(i);
                Game next = pitchGames.get(i + 1);

                LocalDateTime currentEnd = current.getStartTime().plusMinutes(playTime);
                LocalDateTime nextStart = next.getStartTime();

                long gapMinutes = Duration.between(currentEnd, nextStart).toMinutes();

                // Pause erkannt wenn Luecke groesser als normaler Slot
                if (gapMinutes > breakTime + playTime) {
                    pauses.add(new ExportPauseDTO(
                            pauseId++,
                            formatLocalDateTime(currentEnd),
                            formatLocalDateTime(nextStart),
                            pitchToField(pitch),
                            "Pause"
                    ));
                }
            }
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
