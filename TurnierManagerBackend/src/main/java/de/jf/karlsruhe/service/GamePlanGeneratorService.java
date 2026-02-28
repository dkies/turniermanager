package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.dto.EmergencyGameInsertationDTO;
import de.jf.karlsruhe.model.dto.TeamStatsDTO;
import de.jf.karlsruhe.model.enums.GameStatus;
import de.jf.karlsruhe.model.enums.RoundType;
import de.jf.karlsruhe.model.enums.ScheduledItemType;
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

    private final ScheduledItemRepository scheduledItemRepository;
    private final ScheduledGameRepository scheduledGameRepository;
    private final PitchRepository pitchRepository;
    private final LeagueRepository leagueRepository;
    private final RoundRepository roundRepository;
    private final TournamentRepository tournamentRepository;
    private final TeamRepository teamRepository;
    private final AgeGroupRepository ageGroupRepository;

    /**
     * Sammelt die nächstverfügbare Startzeit für alle Pitches einer Altersgruppe,
     * unter Berücksichtigung der Break Time.
     */
    public Map<Pitch, LocalDateTime> getNextAvailableTimePerPitch(
            AgeGroup ageGroup, LocalDateTime tournamentStartTime, int initialBreakSeconds) {

        List<Pitch> pitches = pitchRepository.findByAgeGroup(ageGroup);
        Map<Pitch, LocalDateTime> pitchNextAvailableTimes = new HashMap<>();

        for (Pitch pitch : pitches) {
            Optional<LocalDateTime> latestEndTime = scheduledItemRepository.findLatestEndTimeByPitchId(pitch.getId());

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
     *
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

        int nextNumber = getNextGameNumber();
        for (RoundRobinScheduler.GamePair pairing : allFixtures) {

            Pitch bestPitch = findBestAvailablePitch(pitchNextAvailableTimes);
            LocalDateTime desiredStartTime = pitchNextAvailableTimes.get(bestPitch);

            System.out.println(desiredStartTime);

            LocalDateTime actualStartTime = desiredStartTime;

            LocalDateTime actualEndTime = actualStartTime.plus(gameDuration);

            ScheduleItem gameItem = ScheduleItem.builder()
                    .ageGroup(ageGroup)
                    .itemType(ScheduledItemType.GAME)
                    .startTime(actualStartTime)
                    .endTime(actualEndTime)
                    .scheduledPitch(bestPitch)
                    .status(GameStatus.SCHEDULED)
                    .league(league)
                    .build();
            gameItem = scheduledItemRepository.save(gameItem);

            ScheduledGame game = ScheduledGame.builder()
                    .teamA(pairing.teamA())
                    .teamB(pairing.teamB())
                    .gameNumber(nextNumber++)
                    .scheduleItem(gameItem)
                    //.status(GameStatus.SCHEDULED)
                    .build();
            scheduledGameRepository.save(game);

            pitchNextAvailableTimes.put(bestPitch, actualEndTime.plusSeconds(breakTimeSeconds));
        }
    }

    /**
     * Auswertung der einzelnen Games
     */
    public List<TeamStatsDTO> getTeamStatisticsForLeague(League league) {

        List<Team> teams = league.getTeams();
        List<ScheduledGame> finishedGames = scheduledGameRepository.findFinishedGamesByLeague(
                league.getId(),
                GameStatus.COMPLETED
        );

        Map<Team, TeamStatsDTO> statsMap = new HashMap<>();

        // Initialisieren aller Teams der Liga in der Map
        for (Team team : teams) {
            statsMap.put(team, new TeamStatsDTO(team, 0, 0, 0, 0, 0));
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
            statsMap.computeIfPresent(teamA, (t, oldStats) -> new TeamStatsDTO(
                    t,
                    oldStats.gamesPlayed() + 1,
                    oldStats.pointsScored() + pointsA,
                    oldStats.pointsAgainst() + pointsB,
                    oldStats.goalsScored() + scoreA,
                    oldStats.goalsAgainst() + scoreB
            ));

            // Aktualisiere Team B Stats
            statsMap.computeIfPresent(teamB, (t, oldStats) -> new TeamStatsDTO(
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
     */
    @Transactional
    public List<Team> rankTeamsByPerformance(League league) {

        List<TeamStatsDTO> statsList = getTeamStatisticsForLeague(league);

        Comparator<TeamStatsDTO> rankingComparator = Comparator
                .comparing((TeamStatsDTO s) -> {
                    if (s.gamesPlayed() == 0) return 0.0;
                    return (double) (s.goalsScored() - s.goalsAgainst()) / s.gamesPlayed();
                }, Comparator.reverseOrder())

                .thenComparing(TeamStatsDTO::goalsScored, Comparator.reverseOrder());

        statsList.sort(rankingComparator);

        return statsList.stream()
                .map(TeamStatsDTO::team)
                .collect(Collectors.toList());
    }


    private List<League> createEqualLeagues(AgeGroup ageGroup, int maxTeamsPerLeague, Tournament tournament, Round round, List<Team> teamsToDivide) {
        int totalTeams = teamsToDivide.size();
        int numberOfLeagues = (int) Math.ceil((double) totalTeams / maxTeamsPerLeague);

        List<League> leagues = new ArrayList<>();
        for (int i = 0; i < numberOfLeagues; i++) {
            League league = League.builder()
                    .name(String.format("Gruppe %s (%s)", (char) ('A' + i), ageGroup.getName()))
                    .tournament(tournament)
                    .ageGroup(ageGroup)
                    .round(round)
                    .teams(new ArrayList<>())
                    .build();
            // Speichern, damit die ID für die ScheduleItems vorhanden ist
            leagues.add(league);
        }

        int leagueIndex = 0;
        HashMap<League, Integer> numberOfTeamsPerLeague = new HashMap<>();
        for (Team team : teamsToDivide) {
            League currentLeague = leagues.get(leagueIndex);
            Integer value = numberOfTeamsPerLeague.get(currentLeague);
            if (value == null) {
                numberOfTeamsPerLeague.put(currentLeague, 1);
            } else {
                value += 1;
                numberOfTeamsPerLeague.put(currentLeague, value);
            }
            leagueIndex = (leagueIndex + 1) % leagues.size();
        }

        Queue<Team> teamsQueue = new LinkedList<>(teamsToDivide);
        for (League league : numberOfTeamsPerLeague.keySet()) {
            int i = numberOfTeamsPerLeague.get(league);
            for (int j = 0; j < i; j++) {
                Team poll = teamsQueue.poll();
                league.getTeams().add(poll);
            }
        }

        List<League> returnLeagues = leagueRepository.saveAll(numberOfTeamsPerLeague.keySet());
        round.setLeagues(returnLeagues);
        tournament.getRounds().add(round);
        return returnLeagues;
    }

    @Transactional
    public void endQualification(int maxTeamsPerLeague, String roundName) {
        Tournament tournament = tournamentRepository.findAll().getFirst();
        if (tournament == null) return;
        Round finalPhase = roundRepository.save(Round.builder().name(roundName).orderIndex(2).roundType(RoundType.FINAL_STAGE).tournament(tournament).build());
        List<League> leagues = leagueRepository.findAll();
        for (League league : leagues) {
            List<Team> rankedTeams = rankTeamsByPerformance(league);
            List<League> equalLeagues = createEqualLeagues(league.getAgeGroup(), maxTeamsPerLeague, tournament, finalPhase, rankedTeams);
            equalLeagues.forEach(item -> generateScheduleForLeague(item, tournament));
        }

    }
    @Transactional
    public void endQualificationDetailed(HashMap<UUID,Integer> maxTeamsPerLeaguePerAgeGroup, String roundName) {
        Tournament tournament = tournamentRepository.findAll().getFirst();
        if (tournament == null) return;
        Round finalPhase = roundRepository.save(Round.builder().name(roundName).orderIndex(2).roundType(RoundType.FINAL_STAGE).tournament(tournament).build());
        List<League> leagues = leagueRepository.findAll();
        for (League league : leagues) {
            List<Team> rankedTeams = rankTeamsByPerformance(league);
            List<League> equalLeagues = createEqualLeagues(league.getAgeGroup(), maxTeamsPerLeaguePerAgeGroup.get(league.getAgeGroup().getId()), tournament, finalPhase, rankedTeams);
            equalLeagues.forEach(item -> generateScheduleForLeague(item, tournament));
        }

    }




    @Transactional
    public ScheduledGame insertEmergencyGame(EmergencyGameInsertationDTO dto) {
        Tournament tournament = tournamentRepository.findAll().getFirst();
        // 1. Validierung und Laden der Entitäten
        Team teamA = teamRepository.findById(dto.teamAId())
                .orElseThrow(() -> new IllegalArgumentException("Team A nicht gefunden: " + dto.teamAId()));
        Team teamB = teamRepository.findById(dto.teamBId())
                .orElseThrow(() -> new IllegalArgumentException("Team B nicht gefunden: " + dto.teamBId()));
        AgeGroup ageGroup = ageGroupRepository.findById(dto.ageGroupId())
                .orElseThrow(() -> new IllegalArgumentException("Altersgruppe nicht gefunden: " + dto.ageGroupId()));
        Pitch pitch = pitchRepository.findById(dto.pitchId())
                .orElseThrow(() -> new IllegalArgumentException("Spielfeld nicht gefunden: " + dto.pitchId()));
        League league = leagueRepository.findById(dto.leagueId()).orElseThrow(() -> new IllegalArgumentException("League nicht gefunden: " + dto.leagueId()));

        // 2. Spielzeit ermitteln
        Duration playTime = Duration.ofSeconds(tournament.getPlayTimeInSeconds());
        LocalDateTime endTime = dto.startTime().plus(playTime);

        // 3. Game Number ermitteln
        int nextGameNumber = getNextGameNumber();

        // 4. ScheduleItem erstellen (Header)
        ScheduleItem scheduleItem = ScheduleItem.builder()
                .startTime(dto.startTime())
                .endTime(endTime)
                .ageGroup(ageGroup)
                .scheduledPitch(pitch)
                .status(GameStatus.SCHEDULED)
                .itemType(ScheduledItemType.GAME)
                .league(league)
                .build();
        scheduleItem = scheduledItemRepository.save(scheduleItem);

        // 5. ScheduledGame erstellen (Detail)
        ScheduledGame scheduledGame = ScheduledGame.builder()
                .gameNumber(nextGameNumber)
                .teamA(teamA)
                .teamB(teamB)
                .teamAScore(0)
                .teamBScore(0)
                //.status(GameStatus.SCHEDULED)
                .scheduleItem(scheduleItem)
                .build();

        return scheduledGameRepository.save(scheduledGame);
    }


    private int getNextGameNumber() {
        return scheduledGameRepository.findMaxGameNumber().orElse(0) + 1;
    }

}