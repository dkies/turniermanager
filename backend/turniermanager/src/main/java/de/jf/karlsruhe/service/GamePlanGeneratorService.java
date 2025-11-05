package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.repos.*;
import de.jf.karlsruhe.util.RoundRobinScheduler;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class GamePlanGeneratorService {

    private final ScheduleItemRepository scheduleItemRepository;
    private final ScheduledGameRepository scheduledGameRepository;
    private final PitchRepository pitchRepository;
    private final LeagueRepository leagueRepository;

    public GamePlanGeneratorService(ScheduleItemRepository scheduleItemRepository,
                                    ScheduledGameRepository scheduledGameRepository,
                                    PitchRepository pitchRepository,
                                    LeagueRepository leagueRepository) {
        this.scheduleItemRepository = scheduleItemRepository;
        this.scheduledGameRepository = scheduledGameRepository;
        this.pitchRepository = pitchRepository;
        this.leagueRepository = leagueRepository;
    }

    // Die korrekte Methode zur Bestimmung der nächsten freien Zeit pro Pitch
    private Map<Pitch, LocalDateTime> getNextAvailableTimePerPitch(AgeGroup ageGroup, LocalDateTime tournamentStartTime, int breakTimeMinutes) {
        // ... (Implementierung wie von Ihnen bereitgestellt) ...
        List<Pitch> pitchesForAgeGroup = pitchRepository.findByAgeGroup(ageGroup);
        Duration transitionTime = Duration.ofMinutes(breakTimeMinutes);

        Map<Pitch, LocalDateTime> nextAvailableTimes = pitchesForAgeGroup.stream()
                .collect(Collectors.toMap(
                        pitch -> pitch,
                        pitch -> tournamentStartTime
                ));

        for (Pitch pitch : pitchesForAgeGroup) {
            scheduleItemRepository.findTopByScheduledPitchOrderByEndTimeDesc(pitch)
                    .ifPresent(lastItem -> {
                        nextAvailableTimes.put(pitch, lastItem.getEndTime().plus(transitionTime));
                    });
        }

        return nextAvailableTimes;
    }

    // Die korrekte Methode zum Finden des Pitch, der am frühesten frei wird
    private Pitch findBestAvailablePitch(Map<Pitch, LocalDateTime> availableTimes) {
        return availableTimes.entrySet().stream()
                .min(Comparator.comparing(Map.Entry::getValue))
                .map(Map.Entry::getKey)
                .orElseThrow(() -> new IllegalStateException("Kein Pitch zur Planung verfügbar."));
    }

    // Methode zur Korrektur der Startzeit aufgrund globaler Pausen
    private LocalDateTime adjustStartTimeForGlobalBreaks(LocalDateTime desiredStartTime, Duration gameDuration) {
        // ... (Implementierung wie von Ihnen bereitgestellt) ...
        List<ScheduleItem> breaks = scheduleItemRepository.findByItemTypeOrderByStartTimeAsc("BREAK");
        LocalDateTime actualStartTime = desiredStartTime;

        for (ScheduleItem breakItem : breaks) {
            LocalDateTime breakStart = breakItem.getStartTime();
            LocalDateTime breakEnd = breakItem.getEndTime();

            if (actualStartTime.isBefore(breakEnd) && actualStartTime.plus(gameDuration).isAfter(breakStart)) {
                actualStartTime = breakEnd;
            }

            if (actualStartTime.isBefore(breakStart)) {
                break;
            }
        }
        return actualStartTime;
    }



    @Transactional
    public void generateScheduleForLeague(League league, Tournament tournament) {
        // ... (Implementierung wie von Ihnen bereitgestellt) ...
        AgeGroup ageGroup = league.getAgeGroup();
        int playTimeMinutes = tournament.getPlayTime();
        int breakTimeMinutes = tournament.getBreakTime();
        Duration gameDuration = Duration.ofMinutes(playTimeMinutes);

        List<RoundRobinScheduler.GamePair> allFixtures = RoundRobinScheduler.generateSortedFixtures(league.getTeams());

        LocalDateTime tournamentStartTime = tournament.getStartTime();
        Map<Pitch, LocalDateTime> pitchNextAvailableTimes =
                getNextAvailableTimePerPitch(ageGroup, tournamentStartTime, breakTimeMinutes);

        for (RoundRobinScheduler.GamePair pairing : allFixtures) {

            // A. Finde den Pitch, der am frühesten frei ist und zur Altersgruppe passt
            Pitch bestPitch = findBestAvailablePitch(pitchNextAvailableTimes);
            LocalDateTime desiredStartTime = pitchNextAvailableTimes.get(bestPitch);

            // B. Zeit unter Berücksichtigung der globalen Pausen anpassen
            LocalDateTime actualStartTime = adjustStartTimeForGlobalBreaks(desiredStartTime, gameDuration);

            // C. ScheduleItem (Header) erstellen und speichern
            ScheduleItem gameItem = ScheduleItem.builder()
                    .ageGroup(ageGroup)
                    .itemType("GAME")
                    .startTime(actualStartTime)
                    .endTime(actualStartTime.plus(gameDuration))
                    .scheduledPitch(bestPitch)
                    .build();
            gameItem = scheduleItemRepository.save(gameItem);

            // D. ScheduledGame (Detail) erstellen und speichern
            ScheduledGame game = ScheduledGame.builder()
                    .teamA(pairing.teamA())
                    .teamB(pairing.teamB())
                    .scheduleItem(gameItem)
                    .build();
            scheduledGameRepository.save(game);

            // E. Zeitplan für den Pitch aktualisieren
            pitchNextAvailableTimes.put(bestPitch, gameItem.getEndTime());
        }
    }
}