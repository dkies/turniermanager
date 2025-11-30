package de.jf.karlsruhe.model.repos;

import de.jf.karlsruhe.model.base.ScheduledGame;
import de.jf.karlsruhe.model.enums.GameStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface ScheduledGameRepository extends JpaRepository<ScheduledGame, UUID> {
    //Optional<ScheduledGame> findTopByScheduledPitchOrderByEndTimeDesc(Pitch pitch);
    //List<Game> findByRound(Round round);

    //@Query("SELECT g FROM Game g WHERE g.round IN :rounds")
    //List<Game> findByRounds(List<Round> rounds);

    //List<Game> findByPitchId(UUID pitchId);

    //Optional<Game> findByGameNumber(long gameNumber);

    //List<Game> findByRound_ActiveTrueOrderByStartTimeAsc();

    //List<Game> findByStartTime(LocalDateTime startTime);

    //List<Game> findAllByOrderByStartTimeAsc();

    List<ScheduledGame> findByStatus(GameStatus status);

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
}
