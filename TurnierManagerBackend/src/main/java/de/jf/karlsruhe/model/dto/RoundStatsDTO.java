package de.jf.karlsruhe.model.dto;

import java.util.List;
import java.util.UUID;

public record RoundStatsDTO(
        UUID roundId,
        String roundName,
        List<LeagueTableDTO> leagueTables
) {}

