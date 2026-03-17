package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.dto.GamePlanDTO;
import de.jf.karlsruhe.model.dto.GamePlanEntryDTO;
import de.jf.karlsruhe.model.dto.LeagueScheduleDTO;
import de.jf.karlsruhe.model.enums.GameStatus;
import de.jf.karlsruhe.model.enums.ScheduledItemType;
import de.jf.karlsruhe.model.repos.AgeGroupRepository;
import de.jf.karlsruhe.model.repos.RoundRepository;
import de.jf.karlsruhe.model.repos.ScheduledGameRepository;
import de.jf.karlsruhe.model.repos.ScheduledItemRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GamePlanService {

    private final AgeGroupRepository ageGroupRepository;
    private final RoundRepository roundRepository;
    private final ScheduledItemRepository scheduledItemRepository;
    private final ScheduledGameRepository scheduledGameRepository;

    @Transactional(readOnly = true)
    public GamePlanDTO getGamePlanByAgeGroup(UUID ageGroupId) {

        AgeGroup ageGroup = ageGroupRepository.findById(ageGroupId)
                .orElseThrow(() -> new IllegalArgumentException("Altersgruppe nicht gefunden."));

        Round activeRound = roundRepository.findAll().stream()
                .max(Comparator.comparingInt(Round::getOrderIndex))
                .orElseThrow(() -> new IllegalArgumentException("Keine aktive Runde im Turnier definiert."));

        List<League> relevantLeagues = activeRound.getLeagues().stream()
                .filter(league -> league.getAgeGroup().equals(ageGroup))
                .toList();

        if (relevantLeagues.isEmpty()) {
            throw new IllegalArgumentException("Keine Ligen für diese Altersgruppe in der aktuellen Runde gefunden.");
        }

        List<ScheduleItem> allScheduleItems = scheduledItemRepository
                .findByAgeGroupAndStartTimeIsAfterOrderByStartTimeAsc(
                        ageGroup,
                        LocalDateTime.now().minusHours(1)
                )
                .stream()
                .filter(item -> {
                    return item.getStatus().equals(GameStatus.SCHEDULED);}
                )
        .toList();

        Map<ScheduleItem, ScheduledGame> gameMap = getGameMap(allScheduleItems);

        return createGamePlanDTO(activeRound, ageGroup, allScheduleItems, gameMap, relevantLeagues);
    }

    private Map<ScheduleItem, ScheduledGame> getGameMap(List<ScheduleItem> allScheduleItems) {

        //List<ScheduleItem> breakItems = allScheduleItems.stream()
        //        .filter(item -> ScheduledItemType.BREAK.equals(item.getItemType()))
        //        .toList();

        List<ScheduleItem> gameItems = allScheduleItems.stream()
                // Removed Filtering Breaks from the Schedule.
                //.filter(item -> !ScheduledItemType.BREAK.equals(item.getItemType()))
                .toList();

        List<ScheduledGame> games = scheduledGameRepository.findByScheduleItemIn(gameItems);

        return games.stream()
                .filter(game -> game.getScheduleItem().getStatus() == GameStatus.SCHEDULED)
                .collect(Collectors.toMap(
                        ScheduledGame::getScheduleItem,
                        game -> game
                ));
    }

    private GamePlanDTO createGamePlanDTO(
            Round activeRound,
            AgeGroup ageGroup,
            List<ScheduleItem> allScheduleItems,
            Map<ScheduleItem, ScheduledGame> gameMap,
            List<League> relevantLeagues)
    {
        List<LeagueScheduleDTO> leagueSchedules = new ArrayList<>();

        for (League league : relevantLeagues) {
            Set<ScheduleItem> processedBreaks = new HashSet<>();

            List<GamePlanEntryDTO> entries = allScheduleItems.stream()
                    .map(item -> mapItemToGamePlanEntryDTO(item, gameMap.get(item), league, processedBreaks))
                    .filter(Optional::isPresent)
                    .map(Optional::get)
                    .collect(Collectors.toList());

            if (!entries.isEmpty()) {
                leagueSchedules.add(new LeagueScheduleDTO(league.getName(), entries));
            }
        }

        return new GamePlanDTO(activeRound.getName(), ageGroup.getName(), leagueSchedules);
    }

    private Optional<GamePlanEntryDTO> mapItemToGamePlanEntryDTO(
            ScheduleItem item,
            ScheduledGame game,
            League targetLeague,
            Set<ScheduleItem> processedBreaks)
    {
        if (ScheduledItemType.GAME.equals(item.getItemType()) && game != null) {
            if (targetLeague.getTeams().contains(game.getTeamA()) && targetLeague.getTeams().contains(game.getTeamB())) {
                return Optional.of(new GamePlanEntryDTO(
                        ScheduledItemType.GAME.toString(),
                        item.getScheduledPitch() != null ? item.getScheduledPitch().getName() : "N/A",
                        item.getStartTime(),
                        item.getEndTime(),
                        Optional.of(game.getTeamA().getName()),
                        Optional.of(game.getTeamB().getName()),
                        Optional.of(game.getGameNumber())
                ));
            }
            return Optional.empty();
        }

        if (ScheduledItemType.BREAK.equals(item.getItemType())) {
            if (!processedBreaks.contains(item)) {

                processedBreaks.add(item);

                return Optional.of(new GamePlanEntryDTO(
                        ScheduledItemType.BREAK.toString(),
                        item.getScheduledPitch() != null ? item.getScheduledPitch().getName() : "All",
                        item.getStartTime(),
                        item.getEndTime(),
                        Optional.empty(),
                        Optional.empty(),
                        Optional.empty()
                ));
            }
            return Optional.empty();
        }

        return Optional.empty();
    }
}