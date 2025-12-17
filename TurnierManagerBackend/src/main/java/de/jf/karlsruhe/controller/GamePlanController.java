package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.dto.GamePlanDTO;
import de.jf.karlsruhe.service.GamePlanService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/gameplan")
@RequiredArgsConstructor
public class GamePlanController {

    private final GamePlanService gamePlanService;

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
}