package de.jf.karlsruhe.model.repos;

import de.jf.karlsruhe.model.base.AgeGroup;
import de.jf.karlsruhe.model.base.Pitch;
import de.jf.karlsruhe.model.base.ScheduleItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ScheduledItemRepository extends JpaRepository<ScheduleItem, UUID> {

    @Query("SELECT MAX(si.endTime) FROM ScheduleItem si WHERE si.ageGroup = :ageGroup")
    Optional<LocalDateTime> findLatestEndTimeByAgeGroup(AgeGroup ageGroup);


    @Query("SELECT MAX(si.endTime) FROM ScheduleItem si WHERE si.scheduledPitch.id = :pitchId")
    Optional<LocalDateTime> findLatestEndTimeByPitchId(UUID pitchId);

    List<ScheduleItem> findByAgeGroup(AgeGroup ageGroup);

    List<ScheduleItem> findByScheduledPitchAndStartTimeIsAfterOrderByStartTimeAsc(Pitch pitch, LocalDateTime minus);

    @Query("SELECT si FROM ScheduleItem si WHERE si.startTime >= :startTime ORDER BY si.startTime ASC")
    List<ScheduleItem> findItemsStartingAtOrAfter(LocalDateTime startTime);

    List<ScheduleItem> findByAgeGroupAndStartTimeIsAfterOrderByStartTimeAsc(AgeGroup ageGroup, LocalDateTime startTime);
}

