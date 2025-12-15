package de.jf.karlsruhe.model.repos;

import de.jf.karlsruhe.model.base.AgeGroup;
import de.jf.karlsruhe.model.base.Pitch;
import de.jf.karlsruhe.model.base.ScheduledGame;
import de.jf.karlsruhe.model.enums.GameStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ScheduledGameRepository extends JpaRepository<ScheduledGame, UUID> {

    List<ScheduledGame> findByStatus(GameStatus status);

    @Query("SELECT MAX(g.gameNumber) FROM ScheduledGame g")
    Optional<Integer> findMaxGameNumber();

    @Query("""
        SELECT sg 
        FROM ScheduledGame sg
        JOIN sg.scheduleItem si
        JOIN si.ageGroup ag
        JOIN League l ON l.ageGroup = ag AND l.id = :leagueId
        WHERE sg.status = :status
    """)
    List<ScheduledGame> findGamesByLeagueIdAndStatus(
            @Param("leagueId") UUID leagueId,
            @Param("status") GameStatus status
    );

    Optional<ScheduledGame> findByGameNumber(int number);
    List<ScheduledGame> findByScheduleItem_ScheduledPitchAndStatusIsNotOrderByScheduleItem_StartTimeAsc(
            Pitch pitch,
            GameStatus status
    );
}

