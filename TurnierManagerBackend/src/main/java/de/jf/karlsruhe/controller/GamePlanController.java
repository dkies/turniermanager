package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.dto.ExtendedGameDTO;
import de.jf.karlsruhe.model.dto.GamePlanDTO;
import de.jf.karlsruhe.model.dto.GameScheduleDateTimeDTO;
import de.jf.karlsruhe.service.GamePlanService;
import de.jf.karlsruhe.service.GameScoreService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/gameplan")
@RequiredArgsConstructor
public class GamePlanController {

    private final GamePlanService gamePlanService;
    private final GameScoreService gameScoreService;

    /**
     * Holt den Spielplan für die aktuell aktive Runde einer spezifischen Altersgruppe.
     * GET /gameplan/agegroup/{ageGroupId}
     */
    @GetMapping("/agegroup/{ageGroupId}")
    public ResponseEntity<GamePlanDTO> getGamePlanByAgeGroup(@PathVariable UUID ageGroupId) {
        try {
            GamePlanDTO gamePlan = gamePlanService.getGamePlanByAgeGroup(ageGroupId);
            return ResponseEntity.ok(gamePlan);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/get-all-games-listed-extended")
    public ResponseEntity<List<ExtendedGameDTO>> getAllGames() {
        List<ExtendedGameDTO> games = gameScoreService.getAllGamesExtended();
        if (games.isEmpty()) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(games);
    }

    @GetMapping("/activeGamesSortedDateTimeList")
    public ResponseEntity<List<GameScheduleDateTimeDTO>> getActiveGames() {
        return ResponseEntity.ok(gameScoreService.getActiveGamesSortedDateTimeList());
    }
}