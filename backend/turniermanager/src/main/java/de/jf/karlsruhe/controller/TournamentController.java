package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.dto.EndQualificationRoundDTO;
import de.jf.karlsruhe.model.dto.TournamentCreationDTO;
import de.jf.karlsruhe.service.GamePlanGeneratorService;
import de.jf.karlsruhe.service.TournamentManagementService;
import lombok.AllArgsConstructor;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/turnier")
@AllArgsConstructor
public class TournamentController {

    private final GamePlanGeneratorService gamePlanGeneratorService;
    private final TournamentManagementService tournamentManagementService;

    @PostMapping("/create")
    private void createTournament(@RequestBody TournamentCreationDTO tournamentCreationDTO) {
        tournamentManagementService.createTournament(tournamentCreationDTO);
    }


    @PostMapping("/endQualification")
    private void endQualificationRound(@RequestBody EndQualificationRoundDTO endQualificationRoundDTO) {
        gamePlanGeneratorService.endQualification(endQualificationRoundDTO.maxTeamsPerLeague(), endQualificationRoundDTO.roundName());
    }


}