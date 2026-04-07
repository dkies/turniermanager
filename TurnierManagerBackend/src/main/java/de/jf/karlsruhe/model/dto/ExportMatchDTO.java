package de.jf.karlsruhe.model.dto;

public record ExportMatchDTO(
        int id,
        String startTime,
        Object field,
        String teamA,
        String teamB,
        String status,
        Integer scoreA,
        Integer scoreB
) {}
