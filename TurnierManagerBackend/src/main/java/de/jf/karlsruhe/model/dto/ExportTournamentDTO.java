package de.jf.karlsruhe.model.dto;

import java.util.List;

public record ExportTournamentDTO(
        String tournamentName,
        String lastUpdated,
        List<ExportAgeGroupRefDTO> ageGroups
) {}
