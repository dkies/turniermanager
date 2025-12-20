package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.dto.RoundStatsDTO;
import de.jf.karlsruhe.service.RoundStatsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/stats")
@RequiredArgsConstructor
public class RoundStatsController {

    private final RoundStatsService roundStatsService;

    @GetMapping("/agegroup/{ageGroupId}")
    public ResponseEntity<RoundStatsDTO> getRoundStatsByAgeGroup(@PathVariable UUID ageGroupId) {
        try {
            return ResponseEntity.ok(roundStatsService.getStatsByAgeGroup(ageGroupId));
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/{roundId}")
    public ResponseEntity<RoundStatsDTO> getRoundStats(@PathVariable UUID roundId) {
        try {
            return ResponseEntity.ok(roundStatsService.getStatsByRoundId(roundId));
        } catch (Exception e) {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/tournament")
    public ResponseEntity<RoundStatsDTO> getRoundStatsForTournament() {
        return ResponseEntity.ok(roundStatsService.getStatsForTournament());
    }

    @GetMapping("/whole-tournament")
    public ResponseEntity<List<RoundStatsDTO>> getRoundStatsForWholeTournament() {
        return ResponseEntity.ok(roundStatsService.getAllStatsForTournament());
    }
}