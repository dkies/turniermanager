package de.jf.karlsruhe.model.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record BreakSingleCreationDTO(
        LocalDateTime startTime,
        int amountOfBreaks,
        UUID ageGroupName,
        String message
) {}