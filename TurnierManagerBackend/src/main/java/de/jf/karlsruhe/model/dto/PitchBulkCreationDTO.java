package de.jf.karlsruhe.model.dto;

import java.util.List;

public record PitchBulkCreationDTO(
        List<PitchCreationDTO> pitches
) {}