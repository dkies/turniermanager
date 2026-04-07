package de.jf.karlsruhe.model.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record GameDTO(
        UUID id,
        LocalDateTime startTime,
        int gameNumber,
        String teamA,
        String teamB,
        String pitch,
        String leagueName,
        String ageGroupName,
        String status,
        String type
) {
}
