package de.jf.karlsruhe.model.dto;

import java.time.LocalDateTime;
import java.util.Optional;

public record GamePlanEntryDTO(
        String itemType,
        String pitchName,
        LocalDateTime startTime,
        LocalDateTime endTime,
        // Nur bei GAME:
        Optional<String> teamAName,
        Optional<String> teamBName,
        Optional<Integer> gameNumber
) {}