package de.jf.karlsruhe.model.dto;

import java.time.LocalDateTime;

public record TimingRefreshRequestDTO(
        LocalDateTime plannedStartTime
) {}