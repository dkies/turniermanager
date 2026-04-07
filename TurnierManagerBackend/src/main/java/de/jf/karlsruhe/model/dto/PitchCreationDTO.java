package de.jf.karlsruhe.model.dto;

import java.util.UUID;

public record PitchCreationDTO(
        String name,

        UUID allowedAgeGroupId
) {}