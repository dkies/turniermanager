package de.jf.karlsruhe.model.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record EmergencyGameInsertationDTO(
        UUID teamAId,
        UUID teamBId,
        UUID ageGroupId,
        UUID pitchId,
        LocalDateTime startTime
) {
}
