package de.jf.karlsruhe.model.dto;

import java.util.List;

public record TeamBulkCreationDTO(
        List<TeamCreationDTO> teams
) {
}