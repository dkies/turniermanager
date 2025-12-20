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
                .filter(l -> filterAgeGroup == null || l.getAgeGroup().equals(filterAgeGroup))
                .map(league -> calculateLeagueTable(league, round.getRoundType()))
                .collect(Collectors.toList());

        return new RoundStatsDTO(round.getId(), round.getName(), tables);
    }

    private LeagueTableDTO calculateLeagueTable(League league, RoundType roundType) {
        List<Team> teams = league.getTeams();

        List<ScheduledGame> leagueGames = scheduledGameRepository.findAll().stream()
                .filter(g -> g.getStatus() == GameStatus.COMPLETED)
                .filter(g -> teams.contains(g.getTeamA()) && teams.contains(g.getTeamB()))
                .toList();

        List<TeamScoreStatsDTO> teamStats = teams.stream()
                .map(team -> computeTeamStats(team, leagueGames, roundType))
                .sorted((t1, t2) -> {
                    if (t1.avgScore().isPresent() && t2.avgScore().isPresent()) {
                        int avgComp = Double.compare(t2.avgScore().get(), t1.avgScore().get());
                        if (avgComp != 0) return avgComp;
                    }

                    int pointsComp = Integer.compare(t2.totalPoints(), t1.totalPoints());
                    if (pointsComp != 0) return pointsComp;

                    int diffComp = Integer.compare(t2.pointsDifference(), t1.pointsDifference());
                    if (diffComp != 0) return diffComp;

                    return Integer.compare(t2.ownScoredGoals(), t1.ownScoredGoals());
                })
                .collect(Collectors.toList());

        return new LeagueTableDTO(league.getId(), league.getName(), league.getAgeGroup(),teamStats);
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
        if (roundType == RoundType.QUALIFICATION && gamesPlayed > 0) {
            avgScore = Optional.of((double) (ownGoals - enemyGoals) / gamesPlayed);
        }

        return new TeamScoreStatsDTO(
                team.getName(), victories, defeats, draws, diff,
                totalPoints, ownGoals, enemyGoals, avgScore
        );
    }
}