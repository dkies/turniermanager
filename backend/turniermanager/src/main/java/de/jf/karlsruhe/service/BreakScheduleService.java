package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.dto.BreakGlobalCreationDTO;
import de.jf.karlsruhe.model.dto.BreakSingleCreationDTO;
import de.jf.karlsruhe.model.repos.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BreakScheduleService {

    private final AgeGroupRepository ageGroupRepository;
    private final ScheduleItemRepository scheduleItemRepository;
    private final ScheduledBreakRepository scheduledBreakRepository;
    private final PitchRepository pitchRepository;
    private final TournamentRepository tournamentRepository;


    // --- 1. Pause für eine spezifische Altersgruppe ---

    @Transactional
    public List<ScheduledBreak> setBreakForAgeGroup(BreakSingleCreationDTO breakCreationDTO) {

        AgeGroup ageGroup = ageGroupRepository.findById(breakCreationDTO.ageGroupName())
                .orElseThrow(() -> new IllegalArgumentException("Altersgruppe nicht gefunden: " + breakCreationDTO.ageGroupName()));

        List<ScheduledBreak> breaksToSave = createBreakEntries(
                breakCreationDTO.startTime(),
                breakCreationDTO.endTime(),
                ageGroup,
                breakCreationDTO.message()
        );

        // Führt die Batch-Speicherung durch
        return batchSaveBreaks(breaksToSave);
    }


    // --- 2. Pause für alle Altersgruppen ---

    @Transactional
    public List<ScheduledBreak> setBreakForAllAgeGroups(BreakGlobalCreationDTO breakGlobalCreationDTO) {

        List<AgeGroup> allAgeGroups = ageGroupRepository.findAll();
        List<ScheduledBreak> breaksToSave = new ArrayList<>();

        // Sammelt FÜR JEDE Altersgruppe die zugehörigen Pauseneinträge
        allAgeGroups.forEach(ageGroup -> {
            List<ScheduledBreak> agBreaks = createBreakEntries(
                    breakGlobalCreationDTO.startTime(),
                    breakGlobalCreationDTO.endTime(),
                    ageGroup,
                    breakGlobalCreationDTO.message()
            );
            breaksToSave.addAll(agBreaks);
        });

        return batchSaveBreaks(breaksToSave);
    }


    /**
     * Speichert ScheduleItems (Header) und ScheduledBreaks (Details) in einem Batch.
     */
    @Transactional
    public List<ScheduledBreak> batchSaveBreaks(List<ScheduledBreak> breaksToSave) {

        List<ScheduleItem> itemsToSave = breaksToSave.stream()
                .map(ScheduledBreak::getScheduleItem)
                .collect(Collectors.toList());

        scheduleItemRepository.saveAll(itemsToSave);
        for (ScheduleItem item : itemsToSave) {
            shiftScheduleDueToBreak(item,tournamentRepository.findAll().getFirst());
        }
        return scheduledBreakRepository.saveAll(breaksToSave);
    }


    private List<ScheduledBreak> createBreakEntries(
            LocalDateTime startTime,
            LocalDateTime endTime,
            AgeGroup ageGroup,
            String message) {

        List<Pitch> pitches = pitchRepository.findByAgeGroup(ageGroup);

        if (pitches.isEmpty()) {
            ScheduleItem item = createBreakScheduleItem(startTime, endTime, ageGroup, null);
            ScheduledBreak breakDetail = createScheduledBreakDetail(message, item);
            return List.of(breakDetail);

        } else {
            return pitches.stream()
                    .map(pitch -> {
                        ScheduleItem item = createBreakScheduleItem(startTime, endTime, ageGroup, pitch);
                        return createScheduledBreakDetail(message, item);
                    })
                    .collect(Collectors.toList());
        }
    }



    private ScheduleItem createBreakScheduleItem(LocalDateTime startTime, LocalDateTime endTime, AgeGroup ageGroup, Pitch pitch) {
        return ScheduleItem.builder()
                .startTime(startTime)
                .endTime(endTime)
                .ageGroup(ageGroup)
                .scheduledPitch(pitch)
                .itemType("BREAK")
                .build();
    }

    private ScheduledBreak createScheduledBreakDetail(String message, ScheduleItem scheduleItem) {
        return ScheduledBreak.builder()
                .message(message)
                .scheduleItem(scheduleItem)
                .build();
    }


    /**
     * Update Methode zum verschieben von Spielen die in Games sind.
     * @param newBreakItem
     * @param tournament
     */
    @Transactional
    public void shiftScheduleDueToBreak(ScheduleItem newBreakItem, Tournament tournament) {

        // 1. Parameter aus dem neuen Pausen-Item
        Pitch pitch = newBreakItem.getScheduledPitch();
        AgeGroup ageGroup = newBreakItem.getAgeGroup();
        LocalDateTime newBreakStart = newBreakItem.getStartTime();
        LocalDateTime newBreakEnd = newBreakItem.getEndTime();

        Duration transitionTime = Duration.ofSeconds(tournament.getBreakTimeInSeconds());

        List<ScheduleItem> affectedGameItems;

        if (pitch != null) {
            affectedGameItems = scheduleItemRepository.findByScheduledPitchAndStartTimeIsAfterOrderByStartTimeAsc(pitch, newBreakStart.minus(Duration.ofSeconds(tournament.getPlayTimeInSeconds())));
        } else if (ageGroup != null) {
            throw new UnsupportedOperationException("Die Verschiebung globaler Pausen in bereits geplanter Zeit ist derzeit nicht unterstützt. Bitte verwenden Sie Pitch-spezifische Pausen.");
        } else {
            return;
        }

        Duration cumulativeShiftDuration = Duration.ZERO;
        boolean shiftStarted = false;

        for (ScheduleItem gameItem : affectedGameItems) {

            if (!"GAME".equals(gameItem.getItemType())) {
                continue;
            }

            LocalDateTime gameStart = gameItem.getStartTime();
            LocalDateTime gameEnd = gameItem.getEndTime();

            if (shiftStarted || gameStart.isBefore(newBreakEnd) && gameEnd.isAfter(newBreakStart)) {

                shiftStarted = true;

                Duration requiredShift = Duration.ZERO;

                if (gameStart.isBefore(newBreakEnd)) {
                    LocalDateTime requiredNewStart = newBreakEnd.plus(transitionTime);
                    requiredShift = Duration.between(gameStart, requiredNewStart);

                    if (requiredShift.isNegative() || requiredShift.isZero()) {
                        requiredShift = Duration.ZERO;
                    }

                    if (cumulativeShiftDuration.isZero()) {
                        cumulativeShiftDuration = requiredShift;
                    }
                }


                if (!cumulativeShiftDuration.isZero()) {

                    gameItem.setStartTime(gameStart.plus(cumulativeShiftDuration));
                    gameItem.setEndTime(gameEnd.plus(cumulativeShiftDuration));

                    scheduleItemRepository.save(gameItem);
                }
            }
        }
    }


}