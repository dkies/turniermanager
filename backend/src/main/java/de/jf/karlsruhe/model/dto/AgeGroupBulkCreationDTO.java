package de.jf.karlsruhe.model.dto;

import java.util.List;

public record AgeGroupBulkCreationDTO(
        List<AgeGroupCreationDTO> ageGroups
) {}