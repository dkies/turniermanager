package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.repos.AgeGroupRepository;
import de.jf.karlsruhe.model.repos.RoundRepository; // Beispielhafte Annahme, dass dieses Repo existiert
import de.jf.karlsruhe.model.repos.TournamentRepository;
import lombok.AllArgsConstructor;
import lombok.Data;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@CrossOrigin(origins = "*")

@RestController
@RequestMapping("/stats")
public class RoundStatsController {

//
//    @Autowired
//    private RoundRepository roundRepository;
//
//    @Autowired
//    private AgeGroupRepository ageGroupRepository;
//    @Autowired
//    private TournamentRepository tournamentRepository;
//
//
//    @GetMapping("/agegroup/{ageGroupId}")
//    @Transactional
//    public ResponseEntity<RoundStatsDTO> getRoundStatsByAgeGroup(@PathVariable UUID ageGroupId) {
//        Optional<AgeGroup> ageGroupOpt = ageGroupRepository.findById(ageGroupId);
//        if (ageGroupOpt.isEmpty()) {
//            return ResponseEntity.notFound().build();
//        }
//        AgeGroup ageGroup = ageGroupOpt.get();
//
//        Optional<Round> activeRoundOpt = roundRepository.findActiveRoundByAgeGroup(ageGroup);
//        if (activeRoundOpt.isEmpty()) {
//            return ResponseEntity.notFound().build();
//        }
//        Round activeRound = activeRoundOpt.get();
//
//        RoundStatsDTO roundStatsDTO = getRoundStatsByRound(activeRound);
//        return ResponseEntity.ok(roundStatsDTO);
//    }
//
//    /**
//     * Endpunkt, um die Spieltabellen jeder Liga einer bestimmten Runde als JSON zu liefern.
//     * Beispielaufruf: GET /api/rounds/{roundId}/stats
//     */
//    @GetMapping("/{roundId}")
//    @Transactional
//    public ResponseEntity<RoundStatsDTO> getRoundStats(@PathVariable UUID roundId) {
//        Optional<Round> roundOpt = roundRepository.findById(roundId);
//        if (roundOpt.isEmpty()) {
//            return ResponseEntity.notFound().build();
//        }
//
//        Round round = roundOpt.get();
//        RoundStatsDTO roundStatsDTO = new RoundStatsDTO(round.getId(), round.getName());
//
//        // Jede Liga der Runde durchgehen und Tabelle berechnen
//        List<League> leagues = round.getLeagues();
//        if (leagues == null) {
//            // Keine Ligen vorhanden -> leere Antwort zurückgeben
//            return ResponseEntity.ok(roundStatsDTO);
//        }
//
//        for (League league : leagues) {
//            LeagueTableDTO leagueTableDTO = new LeagueTableDTO(league.getId(), league.getName());
//
//            // Teams in dieser Liga ermitteln
//            List<Team> teams = league.getTeams();
//            if (teams != null) {
//                // Jedes Team einzeln auswerten
//                for (Team team : teams) {
//                    TeamStatsDTO teamStats = computeTeamStats(round, team);
//                    leagueTableDTO.getTeams().add(teamStats);
//                }
//            }
//            roundStatsDTO.getLeagueTables().add(leagueTableDTO);
//        }
//
//        return ResponseEntity.ok(roundStatsDTO);
//    }
//
//    @GetMapping("/getForTournament")
//    @Transactional
//    public ResponseEntity<List<RoundStatsDTO>> getRoundStatsForTournament() {
//        Tournament tournamentId = tournamentRepository.findAll().getFirst();
//        List<Round> allRoundsByTournamentId = roundRepository.findAllRoundsByTournamentId(tournamentId.getId());
//        List<RoundStatsDTO> roundStatsDTOList = new ArrayList<>();
//        for (Round round : allRoundsByTournamentId) {
//            RoundStatsDTO roundStatsByRound = getRoundStatsByRound(round);
//            roundStatsDTOList.add(roundStatsByRound);
//        }
//        return ResponseEntity.ok(roundStatsDTOList);
//    }
//
//    private RoundStatsDTO getRoundStatsByRound(Round round) {
//        RoundStatsDTO roundStatsDTO = new RoundStatsDTO(round.getId(), round.getName());
//
//        // Jede Liga der Runde durchgehen und Tabelle berechnen
//        List<League> leagues = round.getLeagues();
//        if (leagues == null) {
//            return roundStatsDTO;
//        }
//
//        for (League league : leagues) {
//            LeagueTableDTO leagueTableDTO = new LeagueTableDTO(league.getId(), league.getName());
//
//            // Teams in dieser Liga ermitteln
//            List<Team> teams = league.getTeams();
//            if (teams != null) {
//                // Jedes Team einzeln auswerten
//                List<TeamStatsDTO> teamStatsList = new ArrayList<>();
//                for (Team team : teams) {
//                    TeamStatsDTO teamStats = computeTeamStats(round, team);
//                    teamStatsList.add(teamStats);
//                }
//
//                // Teams nach totalPoints absteigend sortieren
//                teamStatsList.sort(Comparator.comparingInt(TeamStatsDTO::getTotalPoints).reversed());
//
//                leagueTableDTO.setTeams(teamStatsList);
//            }
//            roundStatsDTO.getLeagueTables().add(leagueTableDTO);
//        }
//
//        return roundStatsDTO;
//    }
//
//
//    /**
//     * Ermittelt die Statistik für ein einzelnes Team innerhalb der gegebenen Runde:
//     * Siege, Niederlagen, Unentschieden, Tordifferenz, Gesamtpunkte.
//     */
//    private TeamStatsDTO computeTeamStats(Round round, Team team) {
//        // Spiele in dieser Runde
//        List<Game> allGamesInRound = round.getGames();
//        if (allGamesInRound == null) {
//            return new TeamStatsDTO(team.getName(), 0, 0, 0, 0, 0, 0, 0);
//        }
//
//        // Alle Spiele, an denen das Team beteiligt ist
//        List<Game> teamGames = allGamesInRound.stream()
//                .filter(g -> Objects.equals(g.getTeamA(), team) || Objects.equals(g.getTeamB(), team))
//                .collect(Collectors.toList());
//
//        int siege = 0;
//        int niederlagen = 0;
//        int unentschieden = 0;
//        int punkteDifferenz = 0;
//        int gesamtPunkte = 0;
//        int eigeneTore = 0;
//        int gegnerischeTore = 0;
//
//        for (Game g : teamGames) {
//            int teamAScore = g.getTeamAScore();
//            int teamBScore = g.getTeamBScore();
//
//            // Ermitteln, ob das Team A oder B ist
//            boolean isTeamA = Objects.equals(g.getTeamA(), team);
//
//            // Tore und Gegentore je nach Perspektive
//            int eigeneTorePerGame = isTeamA ? teamAScore : teamBScore;
//            int gegnerischeTorePerGame = isTeamA ? teamBScore : teamAScore;
//
//            // Sieg, Niederlage, Unentschieden
//            if (eigeneTorePerGame > gegnerischeTorePerGame) {
//                siege++;
//                gesamtPunkte += 3;
//            } else if (eigeneTorePerGame < gegnerischeTorePerGame) {
//                niederlagen++;
//                // 0 Punkte
//            } else if (eigeneTorePerGame == gegnerischeTorePerGame && g.getActualStartTime() != null) {
//                unentschieden++;
//                gesamtPunkte += 1;
//            }
//
//            // Tordifferenz
//            punkteDifferenz += (eigeneTorePerGame - gegnerischeTorePerGame);
//            eigeneTore += eigeneTorePerGame;
//            gegnerischeTore += gegnerischeTorePerGame;
//        }
//        return new TeamStatsDTO(team.getName(), siege, niederlagen, unentschieden, punkteDifferenz, gesamtPunkte, eigeneTore, gegnerischeTore);
//    }
//
//    // ---------------------------
//    // DTO-Klassen für die Ausgabe
//    // ---------------------------
//
//    /**
//     * Gesamte Ausgabe für eine Runde:
//     * Speichert die Round-ID, Round-Name sowie die Liste aller Ligen mit ihren Tabellen.
//     */
//    @Data
//    @AllArgsConstructor
//    public static class RoundStatsDTO {
//        private UUID roundId;
//        private String roundName;
//        private List<LeagueTableDTO> leagueTables = new ArrayList<>();
//
//        public RoundStatsDTO(UUID roundId, String roundName) {
//            this.roundId = roundId;
//            this.roundName = roundName;
//        }
//    }
//
//    /**
//     * Hält die Daten für eine Liga-Tabelle:
//     * Enthält Liga-ID, Liga-Name und die Team-Statistiken.
//     */
//    @Data
//    @AllArgsConstructor
//    static class LeagueTableDTO {
//        private UUID leagueId;
//        private String leagueName;
//        private List<TeamStatsDTO> teams = new ArrayList<>();
//
//        public LeagueTableDTO(UUID leagueId, String leagueName) {
//            this.leagueId = leagueId;
//            this.leagueName = leagueName;
//        }
//    }
//
//    /**
//     * Hält die Daten eines Teams in der Liga:
//     * Mannschaftsname, Siege, Niederlagen, Unentschieden, Tordifferenz und Gesamtpunkte.
//     */
//    @Data
//    @AllArgsConstructor
//    static class TeamStatsDTO {
//        private String teamName;
//        private int victories;
//        private int defeats;
//        private int draws;
//        private int pointsDifference;
//        private int totalPoints;
//        private int ownScoredGoals;
//        private int enemyScoredGoals;
//    }

}