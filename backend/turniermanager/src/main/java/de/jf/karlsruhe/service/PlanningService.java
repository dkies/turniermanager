//package de.jf.karlsruhe.service;
//
//import de.jf.karlsruhe.model.base.*;
//import de.jf.karlsruhe.model.repos.BreakRepository;
//import de.jf.karlsruhe.model.repos.GameRepository;
//import de.jf.karlsruhe.model.repos.GameSettingsRepository;
//import de.jf.karlsruhe.model.repos.PitchRepository;
//import jakarta.transaction.Transactional;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.stereotype.Service;
//
//import java.time.LocalDateTime;
//import java.time.LocalTime;
//import java.util.*;
//import java.util.function.Function;
//import java.util.stream.Collectors;
//
//@Service
//public class PlanningService {
//
//    @Autowired
//    private GameRepository gameRepository;
//
//    @Autowired
//    private PitchRepository pitchRepository;
//
//    @Autowired
//    private GameSettingsRepository gameSettingsRepository;
//
//    @Autowired
//    private BreakRepository breakRepository;
//
//
//    private GameSettings getGameSettings() {
//        Optional<GameSettings> settingsOptional = gameSettingsRepository.findAll().stream().findFirst();
//        if (settingsOptional.isEmpty()) {
//            System.err.println("Error: No scheduling settings found in the database.");
//            return new GameSettings(UUID.randomUUID(),LocalDateTime.now(),2,3);
//        }
//        return settingsOptional.get();
//    }
//
//    private Collection<Pitch> getPitchesByAgeGroup(AgeGroup ageGroup) {
//        return pitchRepository.findAll().stream().filter(p -> p.getAgeGroup() == ageGroup).collect(Collectors.toList());
//    }
//
//    @Transactional
//    public Optional<Pitch> findBestPitchForAgeGroup(AgeGroup ageGroup) {
//        // Step 1: Get the last scheduled times for all pitches.
//        Map<Pitch, LocalDateTime> lastScheduledTimes = getLastScheduledTimesPerPitch();
//
//        // Step 2: Filter the pitches by the given age group.
//        List<Pitch> pitchesForAgeGroup = pitchRepository.findByAgeGroup(ageGroup);
//
//        // Step 3: Find the pitch with the earliest available time.
//        return pitchesForAgeGroup.stream()
//                .min(Comparator.comparing(lastScheduledTimes::get));
//    }
//
//
//    @Transactional
//    public Map<Pitch, LocalDateTime> getLastScheduledTimesPerPitch() {
//        Optional<GameSettings> settingsOptional = gameSettingsRepository.findAll().stream().findFirst();
//        if (settingsOptional.isEmpty()) {
//            throw new IllegalStateException("No game settings found in the database.");
//        }
//        GameSettings settings = settingsOptional.get();
//        LocalDateTime tournamentStartTime = settings.getStartTime();
//
//        List<Pitch> allPitches = pitchRepository.findAll();
//
//        return allPitches.stream()
//                .collect(Collectors.toMap(
//                        Function.identity(),
//                        pitch -> {
//                            Optional<ScheduledGame> lastGame = gameRepository.findTopByScheduledPitchOrderByEndTimeDesc(pitch);
//                            Optional<ScheduledBreak> lastBreak = breakRepository.findTopByScheduledPitchOrderByEndTimeDesc(pitch);
//
//                            LocalDateTime latestEventTime = null;
//
//                            if (lastGame.isPresent() && lastBreak.isPresent()) {
//                                latestEventTime = lastGame.get().getEndTime().isAfter(lastBreak.get().getEndTime())
//                                        ? lastGame.get().getEndTime()
//                                        : lastBreak.get().getEndTime();
//                            } else if (lastGame.isPresent()) {
//                                latestEventTime = lastGame.get().getEndTime();
//                            } else if (lastBreak.isPresent()) {
//                                latestEventTime = lastBreak.get().getEndTime();
//                            }
//
//                            if (latestEventTime != null) {
//                                return latestEventTime;
//                            } else {
//                                return tournamentStartTime;
//                            }
//                        }
//                ));
//    }
//
//    @Transactional
//    public void scheduleGamesForAgeGroup(AgeGroup ageGroup, List<ScheduledGame> gamesToSchedule) {
//        gamesToSchedule.sort(Comparator.comparing(ScheduledGame::getId));
//        GameSettings settings = getGameSettings();
//
//        for (ScheduledGame game : gamesToSchedule) {
//            Optional<Pitch> bestPitchOptional = findBestPitchForAgeGroup(ageGroup);
//
//            if (bestPitchOptional.isPresent()) {
//                Pitch bestPitch = bestPitchOptional.get();
//                Map<Pitch, LocalDateTime> lastScheduledTimes = getLastScheduledTimesPerPitch();
//                LocalDateTime nextAvailableTime = lastScheduledTimes.get(bestPitch);
//
//                // Spiel-Daten aktualisieren und speichern
//                game.setScheduledPitch(bestPitch);
//                game.setStartTime(nextAvailableTime);
//                game.setEndTime(nextAvailableTime.plusMinutes(settings.getPlayTime()));
//                gameRepository.save(game);
//            } else {
//                System.out.println("No pitches available for age group: " + ageGroup.getName());
//                break;
//            }
//        }
//    }
//
//    private void createAndSaveBreak(Pitch pitch, LocalDateTime breakStart, int breakDuration, String description) {
//        ScheduledBreak aBreak = new ScheduledBreak();
//        aBreak.setStartTime(breakStart);
//        aBreak.setEndTime(breakStart.plusMinutes(breakDuration));
//        aBreak.setMessage(description);
//        breakRepository.save(aBreak);
//    }
//
//}
