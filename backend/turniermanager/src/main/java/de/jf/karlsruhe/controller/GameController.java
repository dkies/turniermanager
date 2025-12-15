package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.base.ScheduledGame;
import de.jf.karlsruhe.model.dto.EmergencyGameInsertationDTO;
import de.jf.karlsruhe.model.dto.GameScoreUUIDUpdateDTO;
import de.jf.karlsruhe.model.dto.GameScoreUpdateDTO;
import de.jf.karlsruhe.service.GamePlanGeneratorService;
import de.jf.karlsruhe.service.GameScoreService;
import lombok.AllArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/games")
@AllArgsConstructor
public class GameController {

    private GamePlanGeneratorService gamePlanGeneratorService;
    private GameScoreService gameScoreService;


    @PostMapping("/score")
    public ResponseEntity<ScheduledGame> updateScore(@RequestBody GameScoreUpdateDTO dto) {
        try {
            ScheduledGame updatedGame = gameScoreService.updateGameScore(dto);
            return ResponseEntity.ok(updatedGame);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping("/score-by-id")
    public ResponseEntity<ScheduledGame> updateScoreByUuid(@RequestBody GameScoreUUIDUpdateDTO dto) {
        try {
            ScheduledGame updatedGame = gameScoreService.updateGameScoreByUuid(
                    dto.gameId(),
                    dto.teamAScore(),
                    dto.teamBScore());
            return ResponseEntity.ok(updatedGame);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping("/emergency-game")
    public ResponseEntity<ScheduledGame> insertEmergencyGame(@RequestBody EmergencyGameInsertationDTO dto) {
        try {
            ScheduledGame newGame = gamePlanGeneratorService.insertEmergencyGame(dto);
            return new ResponseEntity<>(newGame, HttpStatus.CREATED);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }




//
//    private final GameRepository gameRepository;
//    private final PitchScheduler pitchScheduler;
//    private final GameSettingsRepository gameSettingsRepository;
//
//    /**
//     * Spielergebnisse eintragen/aktualisieren
//     *
//     * @param gameId     ID des Spiels
//     * @param teamAScore Punktzahl von Team A
//     * @param teamBScore Punktzahl von Team B
//     * @return Das aktualisierte Spiel
//     */
//    @PostMapping("/updatebyid/{gameId}")
//    public ResponseEntity<Game> updateGameScores(@PathVariable UUID gameId, @RequestParam int teamAScore, @RequestParam int teamBScore) {
//        // Spiel aus der Datenbank abrufen
//        Game game = gameRepository.findById(gameId).orElseThrow(() -> new IllegalArgumentException("Spiel mit ID " + gameId + " nicht gefunden"));
//
//        // Ergebnisse setzen
//        game.setTeamAScore(teamAScore);
//        game.setTeamBScore(teamBScore);
//
//        // Aktualisiertes Spiel speichern
//        Game updatedGame = gameRepository.save(game);
//        return ResponseEntity.ok(updatedGame);
//    }
//
//    @PostMapping("/update/{gameNumber}")
//    public ResponseEntity<Game> updateGameScoresByNumber(@PathVariable int gameNumber, @RequestParam int teamAScore, @RequestParam int teamBScore) {
//        // Spiel anhand der gameNumber abrufen
//        Game game = gameRepository.findByGameNumber(gameNumber).orElseThrow(() -> new IllegalArgumentException("Spiel mit Nummer " + gameNumber + " nicht gefunden"));
//
//        // Ergebnisse setzen
//        game.setTeamAScore(teamAScore);
//        game.setTeamBScore(teamBScore);
//
//        // Spiel aktualisieren
//        Game updatedGame = gameRepository.save(game);
//        return ResponseEntity.ok(updatedGame);
//    }
//
//
//    /**
//     * Ausgabe für ein bestimmtes Spiel erstellen
//     *
//     * @param gameId ID des Spiels
//     * @return Details zum Spiel
//     */
//    @GetMapping("/{gameId}/details")
//    public ResponseEntity<String> getGameDetails(@PathVariable UUID gameId) {
//        Game game = gameRepository.findById(gameId).orElseThrow(() -> new IllegalArgumentException("Spiel mit ID " + gameId + " nicht gefunden"));
//
//        // Details des Spiels formatiert zurückgeben
//        String gameDetails = String.format("Spiel-ID: %s\n" + "Spielbeginn: %s\n" + "Team A: %s [Punkte: %d]\n" + "Team B: %s [Punkte: %d]\n" + "Spielfeld: %s", game.getId(), game.getStartTime(), game.getTeamA().getName(), game.getTeamAScore(), game.getTeamB().getName(), game.getTeamBScore(), game.getPitch() != null ? game.getPitch().getName() : "Kein Spielfeld");
//        return ResponseEntity.ok(gameDetails);
//    }
//
//    /**
//     * Alle Spiele für ein bestimmtes Spielfeld ausgeben
//     *
//     * @param pitchId ID des Spielfelds
//     * @return Eine Liste von Spielen auf dem Spielfeld
//     */
//    @GetMapping("/pitch/{pitchId}")
//    public ResponseEntity<List<Game>> getGamesByPitch(@PathVariable UUID pitchId) {
//        // Alle Spiele für das betreffende Spielfeld abrufen
//        List<Game> games = gameRepository.findByPitchId(pitchId);
//
//        if (games.isEmpty()) {
//            return ResponseEntity.noContent().build(); // Falls keine Spiele vorhanden sind
//        }
//
//        return ResponseEntity.ok(games);
//    }
//
//    @GetMapping("/getAll")
//    public ResponseEntity<List<ExtendedGameDTO>> getAllGames() {
//        List<Game> games = gameRepository.findAll();
//        List<ExtendedGameDTO> extendedGameDTOs = new ArrayList<>();
//        games.forEach(game -> {
//            String leagueName = game.getRound().getLeagues().stream().filter(league -> (league.getTeams().contains(game.getTeamA()) || league.getTeams().contains(game.getTeamB()))).findFirst().map(League::getName).orElse("Unbekannte Liga");
//
//            String ageGroupName = game.getRound().getLeagues().stream().filter(league -> (league.getTeams().contains(game.getTeamA()) || league.getTeams().contains(game.getTeamB()))).findFirst().map(league -> league.getAgeGroup().getName()).orElse("Unbekannte Altersgruppe");
//
//            extendedGameDTOs.add(new ExtendedGameDTO(game.getId(), game.getStartTime(), game.getGameNumber(), game.getTeamA().getName(), game.getTeamB().getName(), game.getPitch() != null ? game.getPitch().getName() : "Kein Spielfeld", leagueName, ageGroupName, game.getTeamAScore(), game.getTeamBScore()));
//        });
//        return ResponseEntity.ok(extendedGameDTOs);
//    }
//
//
//    @PostMapping("/refreshTimings")
//    public ResponseEntity<String> refreshTimings(@RequestBody TimingRequest request) {
//        GameSettings settings = gameSettingsRepository.findAll().getFirst();
//        LocalDateTime startTime = request.getStartTime();
//        LocalDateTime actualStartTime = request.getActualStartTime();
//        LocalDateTime endTime = request.getEndTime();
//
//        LocalDateTime roundedStartTime = roundToMinute(startTime);
//
//        List<Game> gamesToUpdate = gameRepository.findAll().stream()
//                .filter(game -> roundToMinute(game.getStartTime()).equals(roundedStartTime))
//                .toList();
//
//        gamesToUpdate.forEach(game -> {
//            game.setActualStartTime(actualStartTime);
//            game.setActualEndTime(endTime);
//        });
//
//        gameRepository.saveAll(gamesToUpdate);
//
//        if (actualStartTime.isBefore(startTime)) {
//            Duration duration = Duration.between(actualStartTime, startTime);
//            long minutes = duration.toMinutes();
//            pitchScheduler.advanceGamesAfter(startTime, (int) minutes + settings.getBreakTime());
//            return ResponseEntity.ok("Actual start time was " + minutes + " minutes early.");
//        } else if (actualStartTime.isAfter(startTime)) {
//            Duration duration = Duration.between(startTime, actualStartTime);
//            long minutes = duration.toMinutes();
//            pitchScheduler.delayGamesAfter(startTime, (int) minutes + settings.getBreakTime());
//            return ResponseEntity.ok("Actual start time was " + minutes + " minutes late.");
//        } else {
//            return ResponseEntity.ok("Actual start time was on time.");
//        }
//    }
//
//    @GetMapping("/activeGamesSortedDateTimeList")
//    public List<GameScheduleDateTimeDTO> getActiveGamesSortedDateTimeList() {
//        List<Game> allGames = gameRepository.findAll(); // Alle Spiele abrufen
//        TreeMap<LocalDateTime, List<GameDTO>> groupedGames = new TreeMap<>();
//
//        for (Game game : allGames) {
//            // Spiele mit actualStartTime und endTime überspringen
//            if (game.getActualStartTime() != null && game.getActualEndTime() != null) {
//                continue;
//            }
//            if (!game.getRound().isActive()) continue;
//
//            LocalDateTime startTime = roundToMinute(game.getStartTime()); // Auf Minute runden
//            TeamDTO teamADTO = new TeamDTO(game.getTeamA().getId(), game.getTeamA().getName());
//            TeamDTO teamBDTO = new TeamDTO(game.getTeamB().getId(), game.getTeamB().getName());
//            PitchDTO pitchDTO = new PitchDTO(game.getPitch().getId(), game.getPitch().getName());
//
//            // Liga und Altersgruppe aus der aktiven Runde abrufen
//            String leagueName = game.getRound().getLeagues().stream()
//                    .filter(league -> (league.getTeams().contains(game.getTeamA()) || league.getTeams().contains(game.getTeamB())))
//                    .findFirst()
//                    .map(League::getName)
//                    .orElse("Unbekannte Liga");
//
//            String ageGroupName = game.getRound().getLeagues().stream()
//                    .filter(league -> (league.getTeams().contains(game.getTeamA()) || league.getTeams().contains(game.getTeamB())))
//                    .findFirst()
//                    .map(league -> league.getAgeGroup().getName())
//                    .orElse("Unbekannte Altersgruppe");
//
//            GameDTO gameDTO = new GameDTO(game.getId(), game.getGameNumber(), teamADTO, teamBDTO, pitchDTO, leagueName, ageGroupName);
//            groupedGames.computeIfAbsent(startTime, k -> new ArrayList<>()).add(gameDTO);
//        }
//
//        GameSettings currentGameSettings = gameSettingsRepository.findAll().getFirst();
//        List<GameScheduleDateTimeDTO> result = new ArrayList<>();
//        groupedGames.forEach((startTime, games) -> result.add(new GameScheduleDateTimeDTO(currentGameSettings.getPlayTime(), startTime, games)));
//
//        return result;
//    }
//
//    // Hilfsmethode zum Runden auf Minute
//    private LocalDateTime roundToMinute(LocalDateTime dateTime) {
//        return LocalDateTime.of(
//                dateTime.getYear(),
//                dateTime.getMonth(),
//                dateTime.getDayOfMonth(),
//                dateTime.getHour(),
//                dateTime.getMinute()
//        );
//    }
//
//
//    @Data
//    @NoArgsConstructor
//    @AllArgsConstructor
//    public class ExtendedGameDTO {
//        private UUID id;
//        private LocalDateTime startTime;
//        private long gameNumber;
//        private String teamA;
//        private String teamB;
//        private String pitch;
//        private String leagueName;
//        private String ageGroupName;
//        private int pointsTeamA;
//        private int pointsTeamB;
//    }
//
//    @Data
//    @NoArgsConstructor
//    @AllArgsConstructor
//    public class GameScheduleDateTimeDTO {
//        private int gameDurationInMinutes;
//        private LocalDateTime startTime;
//        private List<GameDTO> games;
//    }
//
//    @Data
//    @NoArgsConstructor
//    @AllArgsConstructor
//    public class GameDTO {
//        private UUID id;
//        private long gameNumber;
//        private TeamDTO teamA;
//        private TeamDTO teamB;
//        private PitchDTO pitch;
//        private String leagueName;
//        private String ageGroupName;
//    }
//
//    @Data
//    @NoArgsConstructor
//    @AllArgsConstructor
//    public class PitchDTO {
//        private UUID id;
//        private String name;
//    }
//
//    @Data
//    @NoArgsConstructor
//    @AllArgsConstructor
//    public class TeamDTO {
//        private UUID id;
//        private String name;
//    }
//
//    @Data
//    @NoArgsConstructor
//    @AllArgsConstructor
//    private static class TimingRequest {
//        private LocalDateTime startTime;
//        private LocalDateTime actualStartTime;
//        private LocalDateTime endTime;
//    }

}