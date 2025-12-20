package de.jf.karlsruhe.model.dto;

import java.util.Optional;

public record TeamScoreStatsDTO(
        String teamName,
        int victories,
        int defeats,
        int draws,
        int pointsDifference,
        int totalPoints,
        int ownScoredGoals,
        int enemyScoredGoals,
        Optional<Double> avgScore
) {}
