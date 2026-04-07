package de.jf.karlsruhe.model.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ExportAgeGroupDTO {
    private String ageGroup;
    private String lastUpdated;
    private List<ExportMatchDTO> matches;
    private List<ExportPauseDTO> pauseTimes;
}
