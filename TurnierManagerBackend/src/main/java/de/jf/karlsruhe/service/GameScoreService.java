package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.ScheduledGame;
import de.jf.karlsruhe.model.dto.GameScoreUpdateDTO;
import de.jf.karlsruhe.model.repos.ScheduledGameRepository;
import de.jf.karlsruhe.model.enums.GameStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GameScoreService {

    private final ScheduledGameRepository scheduledGameRepository;

    @Transactional
    public ScheduledGame updateGameScore(GameScoreUpdateDTO dto) {

        ScheduledGame game = scheduledGameRepository.findByGameNumber(dto.gameNumber())
                .orElseThrow(() -> new IllegalArgumentException("Spielnummer " + dto.gameNumber() + " nicht gefunden."));

        return applyScoreUpdate(game, dto.teamAScore(), dto.teamBScore());
    }

    @Transactional
    public ScheduledGame updateGameScoreByUuid(UUID gameId, int teamAScore, int teamBScore) {

        ScheduledGame game = scheduledGameRepository.findById(gameId)
                .orElseThrow(() -> new IllegalArgumentException("Spiel-ID " + gameId + " nicht gefunden."));

        return applyScoreUpdate(game, teamAScore, teamBScore);
    }

    private ScheduledGame applyScoreUpdate(ScheduledGame game, int teamAScore, int teamBScore) {
        game.setTeamAScore(teamAScore);
        game.setTeamBScore(teamBScore);
        //game.setStatus(GameStatus.COMPLETED);

        return scheduledGameRepository.save(game);
    }
}