package de.jf.karlsruhe.controller;

import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*")

@RestController
@RequestMapping("/gameplan")
public class GamePlanController {

//    @Autowired
//    private RoundRepository roundRepository;
//
//    @Autowired
//    private AgeGroupRepository ageGroupRepository;
//
//    @Transactional
//    @GetMapping("/agegroup/{ageGroupId}")
//    public ResponseEntity<GamePlan> getGamePlanByAgeGroup(@PathVariable UUID ageGroupId) {
//        Optional<AgeGroup> ageGroupOptional = ageGroupRepository.findById(ageGroupId);
//        if (ageGroupOptional.isPresent()) {
//            AgeGroup ageGroup = ageGroupOptional.get();
//            List<Round> rounds = roundRepository.findByAgeGroup(ageGroup);
//            if (!rounds.isEmpty()) {
//                List<Round> list = rounds.stream().filter(Round::isActive).toList();
//                GamePlan gamePlan = createGamePlan(list.getFirst());
//                return ResponseEntity.ok(gamePlan);
//            } else {
//                return ResponseEntity.notFound().build();
//            }
//        } else {
//            return ResponseEntity.notFound().build();
//        }
//    }
//
//    @Transactional
//    protected GamePlan createGamePlan(Round round) {
//        GamePlan gamePlan = new GamePlan();
//        List<LeagueSchedule> leagueSchedules = new ArrayList<>();
//
//        for (League league : round.getLeagues()) {
//            LeagueSchedule leagueSchedule = new LeagueSchedule();
//            leagueSchedule.setLeagueName(league.getName());
//
//            List<GamePlanEntry> entries = league.getRound().getGames().stream().filter(game -> game.getActualStartTime() == null || game.getActualEndTime() == null )
//                    .filter(game -> league.getTeams().contains(game.getTeamA()) && league.getTeams().contains(game.getTeamB()))
//                    .sorted(Comparator.comparing(Game::getStartTime))
//                    .map(this::mapGameToGamePlanEntry)
//                    .collect(Collectors.toList());
//
//            leagueSchedule.setEntries(entries);
//            leagueSchedules.add(leagueSchedule);
//        }
//        gamePlan.setRoundName(round.getName());
//        gamePlan.setLeagues(leagueSchedules);
//        return gamePlan;
//    }
//
//    private GamePlanEntry mapGameToGamePlanEntry(Game game) {
//        GamePlanEntry entry = new GamePlanEntry();
//        entry.setPitchName(game.getPitch().getName());
//        entry.setStartTime(game.getStartTime());
//        entry.setTeamAName(game.getTeamA().getName());
//        entry.setTeamBName(game.getTeamB().getName());
//        return entry;
//    }
//
//
//    @Data
//    public static class GamePlan {
//        private String roundName;
//        private List<LeagueSchedule> leagues;
//    }
//
//    @Data
//    static class LeagueSchedule {
//        private String leagueName;
//        private List<GamePlanEntry> entries;
//
//    }
//
//    @Data
//    static class GamePlanEntry {
//        private String pitchName;
//        private LocalDateTime startTime;
//        private String teamAName;
//        private String teamBName;
//    }

}
