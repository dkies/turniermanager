package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.dto.TeamStats;
import de.jf.karlsruhe.model.enums.GameStatus;
import de.jf.karlsruhe.model.repos.*;
import de.jf.karlsruhe.util.RoundRobinScheduler;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GamePlanGeneratorService {

    private final ScheduleItemRepository scheduleItemRepository;
    private final ScheduledGameRepository scheduledGameRepository;
    private final PitchRepository pitchRepository;
    private final LeagueRepository leagueRepository;

    /**
     * Sammelt die nächstverfügbare Startzeit für alle Pitches einer Altersgruppe,
     * unter Berücksichtigung der Break Time.
     */
    public Map<Pitch, LocalDateTime> getNextAvailableTimePerPitch(
            AgeGroup ageGroup, LocalDateTime tournamentStartTime, int initialBreakSeconds) {

        List<Pitch> pitches = pitchRepository.findByAgeGroup(ageGroup);
        Map<Pitch, LocalDateTime> pitchNextAvailableTimes = new HashMap<>();

        for (Pitch pitch : pitches) {
            Optional<LocalDateTime> latestEndTime = scheduleItemRepository.findLatestEndTimeByPitchId(pitch.getId());

            LocalDateTime nextAvailableTime = latestEndTime
                    // Fügt die Standard-Pause in Sekunden hinzu
                    .map(time -> time.plusSeconds(initialBreakSeconds))
                    .orElse(tournamentStartTime);

            pitchNextAvailableTimes.put(pitch, nextAvailableTime);
        }
        return pitchNextAvailableTimes;
    }

    /**
     * Findet den Pitch, der am frühesten verfügbar ist, basierend auf der aktuellen Map.
     * @param pitchNextAvailableTimes Die Map der Pitches und ihrer nächsten freien Zeitpunkte.
     * @return Der Pitch, der am frühesten frei wird.
     */
    public Pitch findBestAvailablePitch(Map<Pitch, LocalDateTime> pitchNextAvailableTimes) {
        if (pitchNextAvailableTimes.isEmpty()) {
            throw new IllegalStateException("Keine Pitches zur Planung verfügbar.");
        }

        return pitchNextAvailableTimes.entrySet().stream()
                .min(Map.Entry.comparingByValue())
                .map(Map.Entry::getKey)
                .orElseThrow(() -> new IllegalStateException("Interner Fehler: Konnte keinen besten Pitch finden."));
    }

    @Transactional
    public void generateScheduleForLeague(League league, Tournament tournament) {

        AgeGroup ageGroup = league.getAgeGroup();
        int playTimeSeconds = tournament.getPlayTimeInSeconds();
        int breakTimeSeconds = tournament.getBreakTimeInSeconds();

        Duration gameDuration = Duration.ofSeconds(playTimeSeconds);

        List<RoundRobinScheduler.GamePair> allFixtures = RoundRobinScheduler.generateSortedFixtures(league.getTeams());

        LocalDateTime tournamentStartTime = tournament.getStartTime();
        Map<Pitch, LocalDateTime> pitchNextAvailableTimes =
                getNextAvailableTimePerPitch(ageGroup, tournamentStartTime, breakTimeSeconds);

        for (RoundRobinScheduler.GamePair pairing : allFixtures) {

            Pitch bestPitch = findBestAvailablePitch(pitchNextAvailableTimes);
            LocalDateTime desiredStartTime = pitchNextAvailableTimes.get(bestPitch);

            LocalDateTime actualStartTime = desiredStartTime;

            LocalDateTime actualEndTime = actualStartTime.plus(gameDuration);

            ScheduleItem gameItem = ScheduleItem.builder()
                    .ageGroup(ageGroup)
                    .itemType("GAME")
                    .startTime(actualStartTime)
                    .endTime(actualEndTime)
                    .scheduledPitch(bestPitch)
                    .build();
            gameItem = scheduleItemRepository.save(gameItem);

            ScheduledGame game = ScheduledGame.builder()
                    .teamA(pairing.teamA())
                    .teamB(pairing.teamB())
                    .scheduleItem(gameItem)
                    .status(GameStatus.SCHEDULED)
                    .build();
            scheduledGameRepository.save(game);

            pitchNextAvailableTimes.put(bestPitch, actualEndTime.plusSeconds(breakTimeSeconds));
        }
    }

    /**
     * Auswertung der einzelnen Games
     * @param league
     * @return
     */
    public List<TeamStats> getTeamStatisticsForLeague(League league) {

        List<Team> teams = league.getTeams();
        List<ScheduledGame> finishedGames = scheduledGameRepository.findGamesByLeagueIdAndStatus(
                league.getId(),
                GameStatus.COMPLETED
        );

        Map<Team, TeamStats> statsMap = new HashMap<>();

        // Initialisieren aller Teams der Liga in der Map
        for (Team team : teams) {
            statsMap.put(team, new TeamStats(team, 0, 0, 0, 0, 0));
        }

        // Iteration über abgeschlossene Spiele, um Statistiken zu aggregieren
        for (ScheduledGame game : finishedGames) {

            Team teamA = game.getTeamA();
            Team teamB = game.getTeamB();
            int scoreA = game.getTeamAScore();
            int scoreB = game.getTeamBScore();

            // Punktevergabe-Logik (z.B. 3 Punkte für Sieg, 1 für Unentschieden, 0 für Niederlage)
            int pointsA = (scoreA > scoreB) ? 3 : (scoreA == scoreB) ? 1 : 0;
            int pointsB = (scoreB > scoreA) ? 3 : (scoreB == scoreA) ? 1 : 0;

            // Aktualisiere Team A Stats
            statsMap.computeIfPresent(teamA, (t, oldStats) -> new TeamStats(
                    t,
                    oldStats.gamesPlayed() + 1,
                    oldStats.pointsScored() + pointsA,
                    oldStats.pointsAgainst() + pointsB,
                    oldStats.goalsScored() + scoreA,
                    oldStats.goalsAgainst() + scoreB
            ));

            // Aktualisiere Team B Stats
            statsMap.computeIfPresent(teamB, (t, oldStats) -> new TeamStats(
                    t,
                    oldStats.gamesPlayed() + 1,
                    oldStats.pointsScored() + pointsB,
                    oldStats.pointsAgainst() + pointsA,
                    oldStats.goalsScored() + scoreB,
                    oldStats.goalsAgainst() + scoreA
            ));
        }

        return new ArrayList<>(statsMap.values());
    }

    /**
     * Ranking der Teams nach Performance
     * @param league
     * @return
     */
    public List<Team> rankTeamsByPerformance(League league) {

        List<TeamStats> statsList = getTeamStatisticsForLeague(league);

        Comparator<TeamStats> rankingComparator = Comparator
                // 2. Sekundäres Kriterium: Durchschnittliche Tordifferenz pro Spiel (absteigend)
                .comparing((TeamStats s) -> {
                    if (s.gamesPlayed() == 0) return 0.0;
                    return (double) (s.goalsScored() - s.goalsAgainst()) / s.gamesPlayed();
                }, Comparator.reverseOrder())

                // 3. Tertiäres Kriterium (Tie-Breaker): Gesamt-Tore erzielt (absteigend)
                .thenComparing(TeamStats::goalsScored, Comparator.reverseOrder());

        statsList.sort(rankingComparator);

        return statsList.stream()
                .map(TeamStats::team)
                .collect(Collectors.toList());
    }









}