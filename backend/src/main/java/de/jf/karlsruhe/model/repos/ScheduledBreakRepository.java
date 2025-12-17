package de.jf.karlsruhe.model.repos;

import de.jf.karlsruhe.model.base.Pitch;
import de.jf.karlsruhe.model.base.ScheduledBreak;
import de.jf.karlsruhe.model.base.ScheduledGame;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface ScheduledBreakRepository extends JpaRepository<ScheduledBreak, UUID> {

}
