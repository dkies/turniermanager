package de.jf.karlsruhe.model.dto;

import java.time.LocalDateTime;

public record GlobalShiftRequest(
        LocalDateTime threshold,
        long minutes
) {}