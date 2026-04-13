package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.base.Round;
import de.jf.karlsruhe.model.dto.EndQualificationRoundDTO;
import de.jf.karlsruhe.model.dto.EndQualificationRoundDetailedDTO;
import de.jf.karlsruhe.model.dto.TournamentCreationDTO;
import de.jf.karlsruhe.model.enums.RoundType;
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

    @PostMapping("/start-qualification")
    private void createTournament() {
        gamePlanGeneratorService.startQualification();
    }


    @PostMapping("/end-qualification")
    private void endQualificationRound(@RequestBody EndQualificationRoundDTO endQualificationRoundDTO) {
        Round activeRound = tournamentManagementService.getActiveRound();
        if(activeRound.getRoundType() != RoundType.QUALIFICATION ) return;
        gamePlanGeneratorService.cancelCurrentGames();
        gamePlanGeneratorService.endQualification(endQualificationRoundDTO.maxTeamsPerLeague(), endQualificationRoundDTO.roundName());
    }

    @PostMapping("/end-qualification-detailed")
    private void endQualificationRoundDetailed(@RequestBody EndQualificationRoundDetailedDTO endQualificationRoundDetailedDTO) {
        Round activeRound = tournamentManagementService.getActiveRound();
        if(activeRound.getRoundType() != RoundType.QUALIFICATION ) return;
        tournamentManagementService.updateTimeSettings(endQualificationRoundDetailedDTO.playTimeInSeconds(), endQualificationRoundDetailedDTO.breakTimeInSeconds());
        gamePlanGeneratorService.cancelCurrentGames();
        gamePlanGeneratorService.endQualificationDetailed(endQualificationRoundDetailedDTO.maxTeamsPerLeaguePerAgeGroup(), endQualificationRoundDetailedDTO.roundName());
    }
}