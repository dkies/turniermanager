package de.jf.karlsruhe.model.dto;

public record ExportPauseDTO(
        long id,
        String startTime,
        String endTime,
        Object field,
        String description
) {}
