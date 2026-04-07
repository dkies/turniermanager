package de.jf.karlsruhe.model.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record AgeGroupShiftRequest(
        UUID ageGroupId,
        LocalDateTime threshold,
        long minutes
) {}