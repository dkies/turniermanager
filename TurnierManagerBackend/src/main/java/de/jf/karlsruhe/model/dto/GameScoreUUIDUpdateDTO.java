package de.jf.karlsruhe.model.dto;

import java.util.UUID;

public record GameScoreUUIDUpdateDTO(
        UUID gameId,
        int teamAScore,
        int teamBScore) {
}
