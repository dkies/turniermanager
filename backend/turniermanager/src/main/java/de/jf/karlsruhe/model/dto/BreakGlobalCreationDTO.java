package de.jf.karlsruhe.model.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record BreakGlobalCreationDTO(
        LocalDateTime startTime,
        LocalDateTime endTime,
        String message
) {}