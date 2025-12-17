package de.jf.karlsruhe.model.dto;

import java.util.List;

public record GamePlanDTO(
        String roundName,
        String ageGroupName,
        List<LeagueScheduleDTO> leagues
) {}