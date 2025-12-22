package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.dto.ExtendedGameDTO;
import de.jf.karlsruhe.model.dto.GameDTO;
import de.jf.karlsruhe.model.dto.GameScheduleDateTimeDTO;
import de.jf.karlsruhe.model.dto.GameScoreUpdateDTO;
import de.jf.karlsruhe.model.enums.GameStatus;
import de.jf.karlsruhe.model.enums.ScheduledItemType;
import de.jf.karlsruhe.model.repos.RoundRepository;
import de.jf.karlsruhe.model.repos.ScheduledBreakRepository;
import de.jf.karlsruhe.model.repos.ScheduledItemRepository;
import de.jf.karlsruhe.model.repos.ScheduledGameRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GameScoreService {

    private final ScheduledGameRepository scheduledGameRepository;
    private final ScheduledBreakRepository scheduledBreakRepository;

    private final RoundRepository roundRepository;
    private final ScheduledItemRepository scheduledItemRepository;

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

    @Transactional(readOnly = true)
    public List<ExtendedGameDTO> getAllGamesExtended() {
        Round activeRound = getActiveRound();

        return scheduledGameRepository.findAll().stream()
                .map(game -> {
                    ScheduleItem item = game.getScheduleItem();

                    // Liga-Name anhand der Teams in der aktiven Runde suchen
                    String leagueName = activeRound.getLeagues().stream()
                            .filter(l -> l.getTeams().contains(game.getTeamA()) || l.getTeams().contains(game.getTeamB()))
                            .findFirst()
                            .map(League::getName)
                            .orElse("Unbekannte Liga");

                    return new ExtendedGameDTO(
                            game.getId(),
                            item.getStartTime(),
                            game.getGameNumber(),
                            game.getTeamA().getName(),
                            game.getTeamB().getName(),
                            item.getScheduledPitch() != null ? item.getScheduledPitch().getName() : "Kein Spielfeld",
                            leagueName,
                            item.getAgeGroup().getName(),
                            game.getTeamAScore(),
                            game.getTeamBScore(),
                            game.getStatus().toString()
                    );
                })
                .sorted(Comparator.comparingInt(ExtendedGameDTO::gameNumber))
                .collect(Collectors.toList());
    }

    private Round getActiveRound() {
        return roundRepository.findAll().stream()
                // Vergleicht alle Runden anhand ihres orderIndex
                .max(Comparator.comparingInt(Round::getOrderIndex))
                // Wirft eine Exception, falls noch gar keine Runden generiert wurden
                .orElseThrow(() -> new RuntimeException("Keine aktive Runde im System gefunden."));
    }


    @Transactional(readOnly = true)
    public List<GameScheduleDateTimeDTO> getActiveGamesSortedDateTimeList() {
        Round activeRound = getActiveRound();

        // 1. Alle ScheduleItems laden
        List<ScheduleItem> allItems = scheduledItemRepository.findAll();

        // 2. Gruppieren nach exakter Startzeit (TreeMap für chronologische Sortierung)
        TreeMap<LocalDateTime, List<GameDTO>> groupedGames = new TreeMap<>();

        for (ScheduleItem item : allItems) {
            GameDTO dto;

            if (item.getItemType() == ScheduledItemType.GAME) {
                // Logik für ein Spiel
                ScheduledGame game = scheduledGameRepository.findByScheduleItem(item)
                        .orElse(null);
                if (game == null) continue;
                if (game.getStatus() == GameStatus.COMPLETED) continue;

                String leagueName = activeRound.getLeagues().stream()
                        .filter(l -> l.getTeams().contains(game.getTeamA()))
                        .findFirst()
                        .map(League::getName)
                        .orElse("N/A");

                dto = new GameDTO(
                        game.getId(),
                        item.getStartTime(),
                        game.getGameNumber(),
                        game.getTeamA().getName(),
                        game.getTeamB().getName(),
                        item.getScheduledPitch() != null ? item.getScheduledPitch().getName() : "Kein Feld",
                        leagueName,
                        item.getAgeGroup().getName(),
                        game.getStatus().toString(),
                        "GAME"
                );
            } else {
                ScheduledBreak breaks = scheduledBreakRepository.findByScheduleItem(item)
                        .orElse(null);

                if (breaks == null) continue;
                // Logik für eine Pause (ItemType ist BREAK oder CLEANING etc.)
                dto = new GameDTO(
                        breaks.getId(),
                        item.getStartTime(),
                        0,                 // Keine Spielnummer bei Pausen
                        "PAUSE",
                        "PAUSE",
                        "-",
                        "-",
                        item.getAgeGroup().getName(),
                        "COMPLETED",       // Pausen sind im Plan quasi immer "bereit"
                        "BREAK"            // Der Typ, den du im Record ergänzt hast
                );
            }

            groupedGames.computeIfAbsent(item.getStartTime(), k -> new ArrayList<>()).add(dto);
        }

        // 3. Mapping in die finale Liste der Zeit-Slots
        return groupedGames.entrySet().stream()
                .map(entry -> new GameScheduleDateTimeDTO(entry.getKey(), entry.getValue()))
                .collect(Collectors.toList());
    }

}