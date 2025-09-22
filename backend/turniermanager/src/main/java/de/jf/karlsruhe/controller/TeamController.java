package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.base.Team;
import de.jf.karlsruhe.model.dto.TeamsSmall;
import de.jf.karlsruhe.model.repos.TeamRepository;

import java.util.List;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/turniersetup/teams")
public class TeamController {

//    @Autowired
//    private TeamRepository teamRepository;
//
//    @PostMapping("/create")
//    public ResponseEntity<Team> createTeam(@RequestBody Team team) {
//        Team savedTeam = teamRepository.save(team);
//        return ResponseEntity.ok(savedTeam);
//    }
//
//    @PostMapping("/bulk")
//    public ResponseEntity<List<Team>> createTeam(@RequestBody List<Team> teams) {
//        List<Team> savedTeam = teamRepository.saveAll(teams);
//        return ResponseEntity.ok(savedTeam);
//    }
//
//    @DeleteMapping("/team/{id}")
//    public ResponseEntity<Void> deleteTeam(@PathVariable UUID id) {
//        if (teamRepository.existsById(id)) {
//            teamRepository.deleteById(id);
//            return ResponseEntity.ok().build();
//        } else {
//            return ResponseEntity.notFound().build();
//        }
//    }
//
//    @GetMapping("/getAll")
//    public ResponseEntity<List<TeamsSmall>> getTeams(
//            @RequestParam(required = false) String league,
//            @RequestParam(required = false) String ageGroup) {
//
//        List<Team> teams = teamRepository.findAll();
//
//        List<TeamsSmall> response = teams.stream()
//                .map(team -> new TeamsSmall(team.getId(), team.getName(), team.getAgeGroup().getName()))
//                .toList();
//
//        return ResponseEntity.ok(response);
//    }
}
