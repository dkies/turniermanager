package de.jf.karlsruhe.model.dto;

import de.jf.karlsruhe.model.enums.RoundType;

import java.util.UUID;

public record RoundCreationDTO(
        String name,

        RoundType roundType,

        int orderIndex

) {}