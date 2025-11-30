package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.AgeGroup;
import de.jf.karlsruhe.model.base.ScheduleItem;
import de.jf.karlsruhe.model.base.ScheduledBreak;
import de.jf.karlsruhe.model.repos.AgeGroupRepository;
import de.jf.karlsruhe.model.repos.ScheduleItemRepository;
import de.jf.karlsruhe.model.repos.ScheduledBreakRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BreakScheduleService {

    private final AgeGroupRepository ageGroupRepository;
    private final ScheduleItemRepository scheduleItemRepository;
    private final ScheduledBreakRepository scheduledBreakRepository;


    // --- 1. Pause für eine spezifische Altersgruppe ---

    /**
     * Legt eine Pause für eine spezifische Altersgruppe an.
     * Es werden ein ScheduleItem und ein zugehöriges ScheduledBreak-Objekt erstellt.
     *
     * @param ageGroupId Die ID der Altersgruppe, für die die Pause gilt.
     * @param startTime Die Startzeit der Pause.
     * @param endTime Die Endzeit der Pause.
     * @param message Eine optionale Nachricht für die Pause (z.B. "Mittagspause").
     * @return Das erstellte und gespeicherte ScheduledBreak-Objekt.
     */
    @Transactional
    public ScheduledBreak setBreakForAgeGroup(
            UUID ageGroupId,
            LocalDateTime startTime,
            LocalDateTime endTime,
            String message) {

        AgeGroup ageGroup = ageGroupRepository.findById(ageGroupId)
                .orElseThrow(() -> new IllegalArgumentException("Altersgruppe nicht gefunden: " + ageGroupId));

        return createBreakEntry(startTime, endTime, ageGroup, message);
    }


    // --- 2. Pause für alle Altersgruppen ---

    /**
     * Legt eine Pause für alle vorhandenen Altersgruppen an.
     *
     * @param startTime Die Startzeit der Pause.
     * @param endTime Die Endzeit der Pause.
     * @param message Eine optionale Nachricht für die Pause (z.B. "Mittagspause").
     * @return Eine Liste der erstellten und gespeicherten ScheduledBreak-Objekte.
     */
    @Transactional
    public List<ScheduledBreak> setBreakForAllAgeGroups(
            LocalDateTime startTime,
            LocalDateTime endTime,
            String message) {

        List<AgeGroup> allAgeGroups = ageGroupRepository.findAll();

        // Erstellt für jede Altersgruppe einen separaten Pauseneintrag
        return allAgeGroups.stream()
                .map(ageGroup -> createBreakEntry(startTime, endTime, ageGroup, message))
                .collect(Collectors.toList());
    }


    // --- HILFSMETHODE ZUR ERSTELLUNG DER ENTITÄTEN ---

    /**
     * Erstellt und speichert die ScheduleItem und die verknüpfte ScheduledBreak Entität.
     */
    private ScheduledBreak createBreakEntry(
            LocalDateTime startTime,
            LocalDateTime endTime,
            AgeGroup ageGroup,
            String message) {

        // 1. ScheduleItem (Header) erstellen und speichern
        ScheduleItem scheduleItem = ScheduleItem.builder()
                .startTime(startTime)
                .endTime(endTime)
                .ageGroup(ageGroup)
                .scheduledPitch(null)
                .itemType("BREAK") // WICHTIG: Setzt den Typ der geplanten Aktivität
                .build();
        scheduleItem = scheduleItemRepository.save(scheduleItem);

        // 2. ScheduledBreak (Detail) erstellen, mit Verknüpfung zum ScheduleItem
        ScheduledBreak scheduledBreak = ScheduledBreak.builder()
                .message(message)
                .scheduleItem(scheduleItem) // Verknüpfung zum Header
                .build();
        return scheduledBreakRepository.save(scheduledBreak);
    }





}