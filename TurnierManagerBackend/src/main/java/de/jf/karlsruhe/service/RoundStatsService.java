package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.dto.*;
import de.jf.karlsruhe.model.enums.GameStatus;
import de.jf.karlsruhe.model.enums.RoundType;
import de.jf.karlsruhe.model.repos.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class RoundStatsService {

    private final RoundRepository roundRepository;
    private final AgeGroupRepository ageGroupRepository;
    private final ScheduledGameRepository scheduledGameRepository;
    private final TournamentRepository tournamentRepository;

    /**
     * Liefert die Statistiken für die aktuell AKTIVE Runde des Turniers.
     */
    @Transactional(readOnly = true)
    public RoundStatsDTO getStatsForTournament() {
        Tournament tournament = tournamentRepository.findAll().stream().findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Kein Turnier gefunden."));

        Round activeRound = roundRepository.findAll().stream()
                .filter(r -> r.getTournament().equals(tournament))
                .max(Comparator.comparingInt(Round::getOrderIndex))
                .orElseThrow(() -> new IllegalArgumentException("Keine aktive Runde gefunden."));

        return calculateRoundStats(activeRound);
    }

    @Transactional(readOnly = true)
    public List<RoundStatsDTO> getAllStatsForTournament() {
        Tournament tournament = tournamentRepository.findAll().stream().findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Kein Turnier gefunden."));

        return roundRepository.findAll().stream()
                .filter(r -> r.getTournament().equals(tournament))
                .sorted(Comparator.comparingInt(Round::getOrderIndex))
                .map(this::calculateRoundStats)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public RoundStatsDTO getStatsByAgeGroup(UUID ageGroupId) {
        AgeGroup ageGroup = ageGroupRepository.findById(ageGroupId)
                .orElseThrow(() -> new IllegalArgumentException("Altersgruppe nicht gefunden."));

        Round activeRound = roundRepository.findAll().stream()
                .max(Comparator.comparingInt(Round::getOrderIndex))
                .orElseThrow(() -> new IllegalArgumentException("Keine Runden vorhanden."));

        return calculateRoundStats(activeRound, ageGroup);
    }

    @Transactional(readOnly = true)
    public RoundStatsDTO getStatsByRoundId(UUID roundId) {
        Round round = roundRepository.findById(roundId)
                .orElseThrow(() -> new IllegalArgumentException("Runde nicht gefunden."));
        return calculateRoundStats(round);
    }

    private RoundStatsDTO calculateRoundStats(Round round) {
        return calculateRoundStats(round, null);
    }

    private RoundStatsDTO calculateRoundStats(Round round, AgeGroup filterAgeGroup) {
        List<LeagueTableDTO> tables = round.getLeagues().stream()
                .sorted(Comparator.comparing(League::getName))
                .filter(l -> filterAgeGroup == null || l.getAgeGroup().equals(filterAgeGroup))
                .map(league -> calculateLeagueTable(league, round.getRoundType()))
                .collect(Collectors.toList());

        return new RoundStatsDTO(round.getId(), round.getName(), tables);
    }

    private LeagueTableDTO calculateLeagueTable(League league, RoundType roundType) {
        List<Team> teams = league.getTeams();

        List<ScheduledGame> leagueGames = scheduledGameRepository.findFinishedGamesByLeague(league.getId(), GameStatus.COMPLETED_AND_STATED);

        List<TeamScoreStatsDTO> teamStats = teams.stream()
                .map(team -> computeTeamStats(team, leagueGames, roundType))
                .sorted((t1, t2) -> {
                    if (t1.avgGoalDiffScore().isPresent() && t2.avgGoalDiffScore().isPresent() && t2.avgPoints().isPresent() && t1.avgPoints().isPresent()) {
                        int avgPointsComp = Double.compare(t2.avgPoints().get(), t1.avgPoints().get());
                        if (avgPointsComp != 0) return avgPointsComp;
                        int avgGoalDiffComp = Double.compare(t2.avgGoalDiffScore().get(), t1.avgGoalDiffScore().get());
                        if (avgGoalDiffComp != 0) return avgGoalDiffComp;
                    }

                    int pointsComp = Integer.compare(t2.totalPoints(), t1.totalPoints());
                    if (pointsComp != 0) return pointsComp;

                    int diffComp = Integer.compare(t2.goalPointsDifference(), t1.goalPointsDifference());
                    if (diffComp != 0) return diffComp;

                    int diffGoalsScored = Integer.compare(t2.ownScoredGoals(), t1.ownScoredGoals());
                    if (diffGoalsScored != 0) return diffGoalsScored;

                    // Wenn alles gleich ist, hash vergleichen (stabiler Sortieralgorithmus)
                    return Integer.compare(t1.hashCode(), t2.hashCode());
                })
                .collect(Collectors.toList());

        return new LeagueTableDTO(league.getId(), league.getName(), league.getAgeGroup(), teamStats);
    }

    private TeamScoreStatsDTO computeTeamStats(Team team, List<ScheduledGame> games, RoundType roundType) {
        int victories = 0, defeats = 0, draws = 0;
        int ownGoals = 0, enemyGoals = 0;

        List<ScheduledGame> teamGames = games.stream()
                .filter(g -> g.getTeamA().equals(team) || g.getTeamB().equals(team))
                .toList();

        for (ScheduledGame g : teamGames) {
            boolean isTeamA = g.getTeamA().equals(team);
            int goalsFor = isTeamA ? g.getTeamAScore() : g.getTeamBScore();
            int goalsAgainst = isTeamA ? g.getTeamBScore() : g.getTeamAScore();

            ownGoals += goalsFor;
            enemyGoals += goalsAgainst;

            if (goalsFor > goalsAgainst) victories++;
            else if (goalsFor < goalsAgainst) defeats++;
            else draws++;
        }

        int totalPoints = (victories * 3) + (draws);
        int diff = ownGoals - enemyGoals;
        int gamesPlayed = teamGames.size();

        Optional<Double> avgScore = Optional.empty();
        Optional<Double> avgPointsComp = Optional.empty();
        if (roundType == RoundType.QUALIFICATION && gamesPlayed > 0) {
            avgScore = Optional.of((double) (ownGoals - enemyGoals) / gamesPlayed);
            avgPointsComp = Optional.of((double) totalPoints / gamesPlayed);
        }

        return new TeamScoreStatsDTO(
                team.getName(), victories, defeats, draws, diff,
                totalPoints, ownGoals, enemyGoals, avgScore, avgPointsComp
        );
    }
}