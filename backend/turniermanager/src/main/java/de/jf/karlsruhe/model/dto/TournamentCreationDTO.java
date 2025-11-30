package de.jf.karlsruhe.model.dto;

import java.time.LocalDateTime;

public record TournamentCreationDTO(

        String name,

        LocalDateTime startTime,

        int breakTimeInSeconds,

        int playTimeInSeconds,

        String venue
) {}