package de.jf.karlsruhe.model.dto;

import java.time.LocalDateTime;
import java.util.List;

public record GameScheduleDateTimeDTO(
        LocalDateTime startTime,
        List<GameDTO> games,
        int playTimeInSeconds
) {}