package de.jf.karlsruhe.model.repos;

import de.jf.karlsruhe.model.base.Pitch;
import de.jf.karlsruhe.model.base.Round;
import de.jf.karlsruhe.model.base.ScheduledGame;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface GameRepository extends JpaRepository<ScheduledGame, UUID> {
    Optional<ScheduledGame> findTopByScheduledPitchOrderByEndTimeDesc(Pitch pitch);
    //List<Game> findByRound(Round round);

    //@Query("SELECT g FROM Game g WHERE g.round IN :rounds")
    //List<Game> findByRounds(List<Round> rounds);

    //List<Game> findByPitchId(UUID pitchId);

    //Optional<Game> findByGameNumber(long gameNumber);

    //List<Game> findByRound_ActiveTrueOrderByStartTimeAsc();

    //List<Game> findByStartTime(LocalDateTime startTime);

    //List<Game> findAllByOrderByStartTimeAsc();
}
