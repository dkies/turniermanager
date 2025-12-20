package de.jf.karlsruhe.model.dto;

import de.jf.karlsruhe.model.base.AgeGroup;

import java.util.List;
import java.util.UUID;

public record LeagueTableDTO(
        UUID leagueId,
        String leagueName,
        AgeGroup ageGroup,
        List<TeamScoreStatsDTO> teams
) {}
