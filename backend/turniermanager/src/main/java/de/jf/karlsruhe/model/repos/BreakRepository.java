package de.jf.karlsruhe.model.repos;

import de.jf.karlsruhe.model.base.Pitch;
import de.jf.karlsruhe.model.base.ScheduledBreak;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface BreakRepository extends JpaRepository<ScheduledBreak, UUID> {
    Optional<ScheduledBreak> findTopByScheduledPitchOrderByEndTimeDesc(Pitch pitch);
}
