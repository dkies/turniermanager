package de.jf.karlsruhe.model.repos;

import de.jf.karlsruhe.model.base.ScheduleItem;
import de.jf.karlsruhe.model.base.ScheduledBreak;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface ScheduleItemRepository extends JpaRepository<ScheduleItem, UUID> {

}
