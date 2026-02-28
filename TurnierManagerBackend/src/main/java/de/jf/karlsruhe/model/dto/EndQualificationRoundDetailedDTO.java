package de.jf.karlsruhe.model.dto;

import java.util.HashMap;
import java.util.UUID;

public record EndQualificationRoundDetailedDTO(
        HashMap<UUID, Integer> maxTeamsPerLeaguePerAgeGroup,
        String roundName
) {}
