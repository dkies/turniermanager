package de.jf.karlsruhe.model.dto;

import java.util.UUID;

public record TeamCreationDTO(
        String name,

        UUID ageGroupId
) {}