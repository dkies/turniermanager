package de.jf.karlsruhe.model.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ExportTournamentDTO {
    private String tournamentName;
    private String lastUpdated;
    private List<ExportAgeGroupRefDTO> ageGroups;
}
