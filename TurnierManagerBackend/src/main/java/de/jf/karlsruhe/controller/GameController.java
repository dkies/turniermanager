package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.base.ScheduledGame;
import de.jf.karlsruhe.model.dto.*;
import de.jf.karlsruhe.service.GamePlanGeneratorService;
import de.jf.karlsruhe.service.GameScoreService;
import de.jf.karlsruhe.service.GameTimingService;
import lombok.AllArgsConstructor;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/games")
@AllArgsConstructor
public class GameController {

    private GamePlanGeneratorService gamePlanGeneratorService;
    private GameScoreService gameScoreService;
    private GameTimingService gameTimingService;


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


    @PostMapping("/refresh-timings")
    public ResponseEntity<String> finishSlot(@RequestBody TimingRefreshRequestDTO request) {
        try {
            if (request.plannedStartTime() == null) {
                return ResponseEntity.badRequest().body("Geplante Startzeit darf nicht leer sein.");
            }

            // Wir nutzen die aktuelle Zeit als Referenz für den Abschluss
            LocalDateTime now = LocalDateTime.now();

            gameTimingService.finishAllItemsAtTime(request.plannedStartTime(), now);

            return ResponseEntity.ok(String.format(
                    "Slot %s wurde erfolgreich beendet. Folgetermine wurden basierend auf %s aktualisiert.",
                    request.plannedStartTime().toLocalTime(),
                    now.toLocalTime()
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Fehler beim Aktualisieren: " + e.getMessage());
        }
    }


}