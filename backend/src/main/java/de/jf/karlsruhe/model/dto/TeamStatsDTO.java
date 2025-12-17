package de.jf.karlsruhe.model.dto;

import de.jf.karlsruhe.model.base.Team;

public record TeamStatsDTO(
        Team team,
        long gamesPlayed,
        int pointsScored,
        int pointsAgainst,
        int goalsScored,
        int goalsAgainst
) {}