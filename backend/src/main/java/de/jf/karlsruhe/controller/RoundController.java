package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.base.Round;
import de.jf.karlsruhe.model.dto.RoundCreationDTO;
import de.jf.karlsruhe.service.RoundService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/rounds")
@RequiredArgsConstructor
public class RoundController {

    private final RoundService roundService;

    @PostMapping
    public ResponseEntity<Round> createRound(@RequestBody RoundCreationDTO dto) {
        try {
            Round savedRound = roundService.createRound(dto);
            return new ResponseEntity<>(savedRound, HttpStatus.CREATED);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    // Read Round by ID
    @GetMapping("/{id}")
    public ResponseEntity<Round> getRoundById(@PathVariable UUID id) {
        return roundService.getRoundById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Read All Rounds
    @GetMapping
    public ResponseEntity<List<Round>> getAllRounds() {
        return ResponseEntity.ok(roundService.getAllRounds());
    }

    // Delete Round
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteRound(@PathVariable UUID id) {
        boolean deleted = roundService.deleteRound(id);

        if (deleted) {
            return ResponseEntity.noContent().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }
}