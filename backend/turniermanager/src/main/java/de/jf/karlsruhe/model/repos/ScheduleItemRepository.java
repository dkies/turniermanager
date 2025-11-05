package de.jf.karlsruhe.model.repos;

import de.jf.karlsruhe.model.base.Pitch;
import de.jf.karlsruhe.model.base.ScheduleItem;
import de.jf.karlsruhe.model.base.ScheduledBreak;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ScheduleItemRepository extends JpaRepository<ScheduleItem, UUID> {
    // Finde das zuletzt beendete Item auf einem bestimmten Pitch
    Optional<ScheduleItem> findTopByScheduledPitchOrderByEndTimeDesc(Pitch pitch);

    // Finde alle Pausen, sortiert nach Startzeit
    List<ScheduleItem> findByItemTypeOrderByStartTimeAsc(String itemType);
}
