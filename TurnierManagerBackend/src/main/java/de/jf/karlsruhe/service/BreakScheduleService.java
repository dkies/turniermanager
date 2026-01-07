package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.dto.BreakGlobalCreationDTO;
import de.jf.karlsruhe.model.dto.BreakSingleCreationDTO;
import de.jf.karlsruhe.model.enums.ScheduledItemType;
import de.jf.karlsruhe.model.repos.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BreakScheduleService {

    private final AgeGroupRepository ageGroupRepository;
    private final ScheduledItemRepository scheduledItemRepository;
    private final ScheduledBreakRepository scheduledBreakRepository;
    private final PitchRepository pitchRepository;
    private final TournamentRepository tournamentRepository;


    /**
     * Löscht einen geplanten Pauseneintrag sowie den zugehörigen ScheduleItem-Header.
     *
     * @param breakId Die UUID der zu löschenden ScheduledBreak-Entität.
     */
    @Transactional
    public void deleteBreak(UUID breakId) {

        ScheduledBreak scheduledBreak = scheduledBreakRepository.findById(breakId)
                .orElseThrow(() -> new IllegalArgumentException("Pause mit ID " + breakId + " nicht gefunden."));

        ScheduleItem scheduleItem = scheduledBreak.getScheduleItem();

        scheduledBreakRepository.delete(scheduledBreak);

        if (scheduleItem != null) {
            scheduledItemRepository.delete(scheduleItem);
        }
    }

    // --- 1. Pause für eine spezifische Altersgruppe ---

    @Transactional
    public List<ScheduledBreak> setBreakForAgeGroup(BreakSingleCreationDTO breakCreationDTO) {

        AgeGroup ageGroup = ageGroupRepository.findById(breakCreationDTO.ageGroupName())
                .orElseThrow(() -> new IllegalArgumentException("Altersgruppe nicht gefunden: " + breakCreationDTO.ageGroupName()));

        List<ScheduledBreak> breaksToSave = createBreakEntries(
                breakCreationDTO.startTime(),
                breakCreationDTO.amountOfBreaks(),
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
                    breakGlobalCreationDTO.amountOfBreaks(),
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

        scheduledItemRepository.saveAll(itemsToSave);
        for (ScheduleItem item : itemsToSave) {
            shiftScheduleDueToBreak(item,tournamentRepository.findAll().getFirst());
        }
        return scheduledBreakRepository.saveAll(breaksToSave);
    }


    private List<ScheduledBreak> createBreakEntries(
            LocalDateTime startTime,
            int amountOfBreaks,
            AgeGroup ageGroup,
            String message) {

        Tournament tournament = tournamentRepository.findAll().getFirst();
        List<Pitch> pitches = pitchRepository.findByAgeGroup(ageGroup);
        List<ScheduledBreak> allBreaks = new ArrayList<>();

        // Zeit berechnen: Ein Block ist Spielzeit + Puffer
        long gameDurationSeconds = tournament.getPlayTimeInSeconds();
        long transitionSeconds = tournament.getBreakTimeInSeconds();
        long totalBlockSeconds = gameDurationSeconds + transitionSeconds;

        // Wir loopen über die Anzahl der gewünschten Pausen-Slots
        for (int i = 0; i < amountOfBreaks; i++) {
            // Berechne Start und Ende für DIESEN spezifischen Slot
            LocalDateTime currentStart = startTime.plusSeconds(i * totalBlockSeconds);
            LocalDateTime currentEnd = currentStart.plusSeconds(gameDurationSeconds);

            if (pitches.isEmpty()) {
                // Falls keine Plätze definiert sind (global für die Altersgruppe)
                ScheduleItem item = createBreakScheduleItem(currentStart, currentEnd, ageGroup, null);
                allBreaks.add(createScheduledBreakDetail(message + " (Slot " + (i + 1) + ")", item));
            } else {
                // Erzeuge den Slot für jeden Pitch
                for (Pitch pitch : pitches) {
                    ScheduleItem item = createBreakScheduleItem(currentStart, currentEnd, ageGroup, pitch);
                    allBreaks.add(createScheduledBreakDetail(message + " (Slot " + (i + 1) + ")", item));
                }
            }
        }

        return allBreaks;
    }



    private ScheduleItem createBreakScheduleItem(LocalDateTime startTime, LocalDateTime endTime, AgeGroup ageGroup, Pitch pitch) {
        return ScheduleItem.builder()
                .startTime(startTime)
                .endTime(endTime)
                .ageGroup(ageGroup)
                .scheduledPitch(pitch)
                .itemType(ScheduledItemType.BREAK)
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
        Pitch pitch = newBreakItem.getScheduledPitch();
        LocalDateTime newBreakStart = newBreakItem.getStartTime();
        LocalDateTime newBreakEnd = newBreakItem.getEndTime();

        // Pufferzeit zwischen Spielen/Pausen
        Duration transitionTime = Duration.ofSeconds(tournament.getBreakTimeInSeconds());
        // Wie lange ein Spiel dauert
        Duration gameDuration = Duration.ofSeconds(tournament.getPlayTimeInSeconds());

        if (pitch == null) return;

        // Lade alle Spiele auf diesem Platz ab dem Zeitpunkt der Pause
        List<ScheduleItem> affectedGameItems = scheduledItemRepository
                .findByScheduledPitchAndStartTimeIsAfterOrderByStartTimeAsc(
                        pitch,
                        newBreakStart.minus(gameDuration)
                );

        // Wir merken uns, wann der Platz frühestens wieder frei ist
        LocalDateTime earliestPossibleStart = newBreakEnd.plus(transitionTime);

        for (ScheduleItem gameItem : affectedGameItems) {
            if (!ScheduledItemType.GAME.equals(gameItem.getItemType())) continue;

            LocalDateTime currentStart = gameItem.getStartTime();
            LocalDateTime currentEnd = gameItem.getEndTime();

            // FALL 1: Das Spiel überschneidet sich mit der Pause oder startet davor/währenddessen
            // ODER FALL 2: Das Spiel würde vor dem Ende des vorherigen (verschobenen) Spiels starten
            if (currentStart.isBefore(earliestPossibleStart) && currentEnd.isAfter(newBreakStart)) {

                // Verschiebe dieses Spiel hinter die Sperrzeit
                gameItem.setStartTime(earliestPossibleStart);
                gameItem.setEndTime(earliestPossibleStart.plus(gameDuration));

                scheduledItemRepository.save(gameItem);

                // Aktualisiere earliestPossibleStart für das NÄCHSTE Spiel
                // Das nächste Spiel darf erst nach diesem Spiel + Puffer starten
                earliestPossibleStart = gameItem.getEndTime().plus(transitionTime);
            }
        }
    }


}