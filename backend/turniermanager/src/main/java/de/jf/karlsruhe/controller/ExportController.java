package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.repos.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/export")
@RequiredArgsConstructor
public class ExportController {

    private final TournamentRepository tournamentRepository;
    private final AgeGroupRepository ageGroupRepository;
    private final GameRepository gameRepository;
    private final RoundRepository roundRepository;
    private final GameSettingsRepository gameSettingsRepository;

    private static final ZoneId ZONE = ZoneId.of("Europe/Berlin");
    private static final DateTimeFormatter ISO_FORMATTER = DateTimeFormatter.ISO_OFFSET_DATE_TIME;
    private static final Pattern NUMBER_PATTERN = Pattern.compile("(\\d+)");

    @GetMapping("/tournament")
    @Transactional
    public ResponseEntity<TournamentExportDTO> exportTournament() {
        List<Tournament> tournaments = tournamentRepository.findAll();
        if (tournaments.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        Tournament tournament = tournaments.getFirst();
        List<AgeGroup> ageGroups = ageGroupRepository.findAll();

        List<AgeGroupRefDTO> ageGroupRefs = ageGroups.stream()
                .map(ag -> new AgeGroupRefDTO(
                        ag.getName().toLowerCase(),
                        ag.getName(),
                        "data/" + ag.getName().toLowerCase() + ".json"
                ))
                .toList();

        TournamentExportDTO dto = new TournamentExportDTO(
                tournament.getName(),
                formatNow(),
                ageGroupRefs
        );

        return ResponseEntity.ok(dto);
    }

    @GetMapping("/agegroup/{slug}")
    @Transactional
    public ResponseEntity<AgeGroupExportDTO> exportAgeGroup(@PathVariable String slug) {
        // Find age group by slug (lowercase name)
        AgeGroup ageGroup = ageGroupRepository.findAll().stream()
                .filter(ag -> ag.getName().toLowerCase().equals(slug.toLowerCase()))
                .findFirst()
                .orElse(null);

        if (ageGroup == null) {
            return ResponseEntity.notFound().build();
        }

        // Get all rounds for this age group
        List<Round> rounds = roundRepository.findByAgeGroup(ageGroup);
        if (rounds.isEmpty()) {
            return ResponseEntity.ok(new AgeGroupExportDTO(
                    ageGroup.getName(),
                    formatNow(),
                    List.of(),
                    List.of()
            ));
        }

        // Get all games from these rounds
        List<Game> allGames = gameRepository.findByRounds(rounds);

        // Filter to games belonging to this age group
        List<Game> ageGroupGames = allGames.stream()
                .filter(game -> belongsToAgeGroup(game, ageGroup))
                .sorted(Comparator.comparing(Game::getStartTime))
                .toList();

        // Map games to export DTOs
        List<MatchExportDTO> matches = ageGroupGames.stream()
                .map(this::mapGameToMatch)
                .toList();

        // Detect pauses from gaps in the schedule
        List<PauseExportDTO> pauseTimes = detectPauses(ageGroupGames);

        AgeGroupExportDTO dto = new AgeGroupExportDTO(
                ageGroup.getName(),
                formatNow(),
                matches,
                pauseTimes
        );

        return ResponseEntity.ok(dto);
    }

    // ---- Mapping helpers ----

    private boolean belongsToAgeGroup(Game game, AgeGroup ageGroup) {
        // Try direct league reference first
        if (game.getLeague() != null && game.getLeague().getAgeGroup() != null) {
            return Objects.equals(game.getLeague().getAgeGroup().getId(), ageGroup.getId());
        }
        // Fallback: traverse round → leagues
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

    private MatchExportDTO mapGameToMatch(Game game) {
        String status = deriveStatus(game);
        Integer scoreA = "scheduled".equals(status) ? null : game.getTeamAScore();
        Integer scoreB = "scheduled".equals(status) ? null : game.getTeamBScore();

        return new MatchExportDTO(
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

    private List<PauseExportDTO> detectPauses(List<Game> games) {
        List<GameSettings> settings = gameSettingsRepository.findAll();
        if (settings.isEmpty() || games.isEmpty()) {
            return List.of();
        }

        GameSettings gs = settings.getFirst();
        int playTime = gs.getPlayTime();
        int breakTime = gs.getBreakTime();
        int normalSlot = playTime + breakTime; // normal time between game starts

        // Group games by pitch
        Map<Pitch, List<Game>> gamesByPitch = games.stream()
                .filter(g -> g.getPitch() != null)
                .collect(Collectors.groupingBy(Game::getPitch));

        List<PauseExportDTO> pauses = new ArrayList<>();
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

                // A pause is detected when the gap is larger than a normal break
                if (gapMinutes > breakTime + playTime) {
                    pauses.add(new PauseExportDTO(
                            pauseId++,
                            formatLocalDateTime(currentEnd),
                            formatLocalDateTime(nextStart),
                            pitchToField(pitch),
                            "Pause"
                    ));
                }
            }
        }

        // Sort pauses by start time
        pauses.sort(Comparator.comparing(PauseExportDTO::getStartTime));
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

    // ---- DTOs ----

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class TournamentExportDTO {
        private String tournamentName;
        private String lastUpdated;
        private List<AgeGroupRefDTO> ageGroups;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AgeGroupRefDTO {
        private String id;
        private String label;
        private String file;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AgeGroupExportDTO {
        private String ageGroup;
        private String lastUpdated;
        private List<MatchExportDTO> matches;
        private List<PauseExportDTO> pauseTimes;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MatchExportDTO {
        private long id;
        private String startTime;
        private Object field;
        private String teamA;
        private String teamB;
        private String status;
        private Integer scoreA;
        private Integer scoreB;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PauseExportDTO {
        private long id;
        private String startTime;
        private String endTime;
        private Object field;
        private String description;
    }
}
