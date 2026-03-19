package de.jf.karlsruhe.model.dto;

import java.util.UUID;

public record SwapRequest(
        UUID idA,
        UUID idB
) {}