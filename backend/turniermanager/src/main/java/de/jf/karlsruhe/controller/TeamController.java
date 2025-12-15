package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.base.Team;
import de.jf.karlsruhe.model.dto.TeamCreationDTO;
import de.jf.karlsruhe.model.dto.TeamBulkCreationDTO;
import de.jf.karlsruhe.model.dto.TeamsSmall;
import de.jf.karlsruhe.service.TeamService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/teams")
@RequiredArgsConstructor
public class TeamController {

    private final TeamService teamService;

    @PostMapping("/create")
    public ResponseEntity<Team> createTeam(@RequestBody TeamCreationDTO dto) {
        try {
            Team savedTeam = teamService.createTeam(dto);
            return new ResponseEntity<>(savedTeam, HttpStatus.CREATED);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @PostMapping("/bulk")
    public ResponseEntity<List<Team>> createTeam(@RequestBody TeamBulkCreationDTO dto) {
        try {
            List<Team> savedTeams = teamService.createMultipleTeams(dto);
            return new ResponseEntity<>(savedTeams, HttpStatus.CREATED);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @DeleteMapping("/delete")
    public ResponseEntity<Void> deleteTeam(@RequestBody UUID id) {
        boolean deleted = teamService.deleteTeam(id);

        if (deleted) {
            return ResponseEntity.noContent().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @GetMapping("/getAll")
    public ResponseEntity<List<TeamsSmall>> getTeams(
            @RequestParam(required = false) String league,
            @RequestParam(required = false) String ageGroup) {

        List<TeamsSmall> response = teamService.getTeamsSmall(league, ageGroup);

        return ResponseEntity.ok(response);
    }
}