package de.jf.karlsruhe.model.repos;

import de.jf.karlsruhe.model.base.*;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ScheduledBreakRepository extends JpaRepository<ScheduledBreak, UUID> {
    Optional<ScheduledBreak> findByScheduleItem(ScheduleItem item);

    void deleteAllByScheduleItemIn(List<ScheduleItem> gamesToCancel);

}
