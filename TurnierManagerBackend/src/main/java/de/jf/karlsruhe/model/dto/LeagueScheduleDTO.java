package de.jf.karlsruhe.model.dto;

import java.util.List;

public record LeagueScheduleDTO(
        String leagueName,
        List<GamePlanEntryDTO> entries
) {}