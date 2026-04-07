package de.jf.karlsruhe.model.repos;

import de.jf.karlsruhe.model.base.AgeGroup;
import de.jf.karlsruhe.model.base.Pitch;
import de.jf.karlsruhe.model.base.ScheduleItem;
import de.jf.karlsruhe.model.base.ScheduledGame;
import de.jf.karlsruhe.model.enums.GameStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ScheduledGameRepository extends JpaRepository<ScheduledGame, UUID> {

    @Query("SELECT MAX(g.gameNumber) FROM ScheduledGame g")
    Optional<Integer> findMaxGameNumber();


    @Query("SELECT g FROM ScheduledGame g " +
            "WHERE g.scheduleItem.league.id = :leagueId " +
            "AND g.scheduleItem.status = :status")
    List<ScheduledGame> findFinishedGamesByLeague(@Param("leagueId") UUID leagueId, @Param("status") GameStatus status);

    Optional<ScheduledGame> findByGameNumber(int number);
    @Query("SELECT g FROM ScheduledGame g " +
            "JOIN g.scheduleItem si " +
            "WHERE si.scheduledPitch = :pitch " +
            "AND si.status <> :status " +
            "ORDER BY si.startTime ASC")
    List<ScheduledGame> findByPitchAndItemStatusNot(@Param("pitch") Pitch pitch, @Param("status") GameStatus status);

    @Query("SELECT g FROM ScheduledGame g " +
            "JOIN g.scheduleItem si " +
            "WHERE si.scheduledPitch = :pitch " +
            "ORDER BY si.startTime ASC")
    List<ScheduledGame> findByPitchOrderByStartTime(@Param("pitch") Pitch pitch);

    List<ScheduledGame> findByScheduleItemIn(List<ScheduleItem> items);

    Optional<ScheduledGame> findByScheduleItem(ScheduleItem item);

    void deleteAllByScheduleItemIn(List<ScheduleItem> gamesToCancel);
}

