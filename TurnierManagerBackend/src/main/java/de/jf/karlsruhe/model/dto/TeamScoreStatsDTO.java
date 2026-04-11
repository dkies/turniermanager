package de.jf.karlsruhe.model.dto;

import java.util.Optional;

public record TeamScoreStatsDTO(
        String teamName,
        int victories,
        int defeats,
        int draws,
        int goalPointsDifference,
        int totalPoints,
        int ownScoredGoals,
        int enemyScoredGoals,
        Optional<Double> avgGoalDiffScore,
        Optional<Double> avgPoints
) {
    @Override
    public int hashCode() {
        return java.util.Objects.hash(teamName, ownScoredGoals, enemyScoredGoals);
    }
}
