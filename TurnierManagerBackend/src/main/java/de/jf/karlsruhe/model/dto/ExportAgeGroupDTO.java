package de.jf.karlsruhe.model.dto;

import java.util.List;

public record ExportAgeGroupDTO(
        String ageGroup,
        String lastUpdated,
        List<ExportMatchDTO> matches,
        List<ExportPauseDTO> pauseTimes
) {}
