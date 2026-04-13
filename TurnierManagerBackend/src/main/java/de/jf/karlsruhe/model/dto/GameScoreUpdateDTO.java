package de.jf.karlsruhe.model.dto;

public record GameScoreUpdateDTO(
        int gameNumber,

        int teamAScore,

        int teamBScore
) {}