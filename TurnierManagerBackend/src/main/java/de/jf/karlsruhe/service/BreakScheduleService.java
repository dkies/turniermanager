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
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class BreakScheduleService {

    private final AgeGroupRepository ageGroupRepository;
    private final ScheduledItemRepository scheduledItemRepository;
    private final ScheduledBreakRepository scheduledBreakRepository;
    private final PitchRepository pitchRepository;
    private final TournamentRepository tournamentRepository;

    @Transactional
    public List<ScheduledBreak> setBreakForAgeGroup(BreakSingleCreationDTO dto) {
        AgeGroup ageGroup = ageGroupRepository.findById(dto.ageGroupName())
                .orElseThrow(() -> new IllegalArgumentException("Altersgruppe nicht gefunden"));

        List<Pitch> pitches = pitchRepository.findByAgeGroup(ageGroup);
        return processBreaks(pitches, dto.startTime(), dto.amountOfBreaks(), dto.message(), ageGroup);
    }

    @Transactional
    public List<ScheduledBreak> setBreakForAllAgeGroups(BreakGlobalCreationDTO dto) {
        List<AgeGroup> allGroups = ageGroupRepository.findAll();
        List<ScheduledBreak> allCreatedBreaks = new ArrayList<>();

        for (AgeGroup group : allGroups) {
            List<Pitch> pitches = pitchRepository.findByAgeGroup(group);
            allCreatedBreaks.addAll(processBreaks(pitches, dto.startTime(), dto.amountOfBreaks(), dto.message(), group));
        }
        return allCreatedBreaks;
    }

    private List<ScheduledBreak> processBreaks(List<Pitch> pitches, LocalDateTime start, int count, String msg, AgeGroup group) {
        Tournament tournament = tournamentRepository.findAll().getFirst();
        List<ScheduledBreak> createdBreaks = new ArrayList<>();

        for (Pitch pitch : pitches) {
            // 1. FINDE ÜBERSCHNEIDUNGEN: Lade alle Items, die ENTWEDER nach 'start' beginnen
            // ODER vor 'start' begonnen haben, aber erst nach 'start' enden.
            List<ScheduleItem> affectedItems = scheduledItemRepository
                    .findByScheduledPitchAndEndTimeIsAfterOrderByStartTimeAsc(pitch, start);

            // 2. Neue Pausen erzeugen
            List<ScheduleItem> newBreakItems = createBreakItems(pitch, group, start, count, tournament);

            // 3. Kombinieren: Pausen haben absolute Priorität
            //timeline.addAll(newBreakItems);
            List<ScheduleItem> timeline = new ArrayList<>(affectedItems);

            // 4. Sortieren: Pausen stechen Spiele bei gleicher Zeit
            timeline.sort(Comparator.comparing(ScheduleItem::getStartTime));

            List<ScheduleItem> sortedTimeLine = insertBreaks(timeline, newBreakItems, tournament, start);

            // 5. Die Kettenreaktion (Reschedule)
            //rescheduleTimeline(timeline, tournament, start);

            // 6. Speichern
            scheduledItemRepository.saveAll(sortedTimeLine);

            for (ScheduleItem item : newBreakItems) {
                createdBreaks.add(scheduledBreakRepository.save(
                        ScheduledBreak.builder().message(msg).scheduleItem(item).build()
                ));
            }
        }
        return createdBreaks;
    }

    private List<ScheduleItem> insertBreaks(List<ScheduleItem> timeline, List<ScheduleItem> newBreakItems, Tournament t, LocalDateTime chainStart) {
        long gameSec = t.getPlayTimeInSeconds();
        long breakSec = t.getBreakTimeInSeconds();

        long calculatedBreakLength = newBreakItems.size() * (breakSec + gameSec);


        for (ScheduleItem item : timeline) {
                item.setStartTime(item.getStartTime().plusSeconds(calculatedBreakLength));
                item.setEndTime(item.getEndTime().plusSeconds(calculatedBreakLength));
        }
        timeline.addAll(newBreakItems);
        timeline.sort(Comparator.comparing(ScheduleItem::getStartTime));

        // Correction for mini delays
        //for (int i = 0; i < timeline.size() - 1; i++) {
        //    long breakDifference = Duration.between(timeline.get(i).getEndTime(), timeline.get(i + 1).getStartTime()).toSeconds();
        //    if ( breakDifference != breakSec) {
        //        timeline.get(i + 1).setStartTime(timeline.get(i).getEndTime().plusSeconds(breakSec));
        //        timeline.get(i + 1).setEndTime(timeline.get(i + 1).getStartTime().plusSeconds(gameSec));
        //    }
        //}

        return timeline;
    }

    private List<ScheduleItem> createBreakItems(Pitch p, AgeGroup g, LocalDateTime start, int count, Tournament t) {
        List<ScheduleItem> items = new ArrayList<>();
        long blockSec = t.getPlayTimeInSeconds() + t.getBreakTimeInSeconds();

        for (int i = 0; i < count; i++) {
            LocalDateTime slotStart = start.plusSeconds(i * blockSec);
            items.add(ScheduleItem.builder()
                    .startTime(slotStart)
                    .endTime(slotStart.plusSeconds(t.getPlayTimeInSeconds()))
                    .itemType(ScheduledItemType.BREAK)
                    .scheduledPitch(p)
                    .ageGroup(g)
                    .build());
        }
        return items;
    }

    @Transactional
    public void deleteBreak(UUID breakId) {
        ScheduledBreak b = scheduledBreakRepository.findById(breakId).orElseThrow();
        ScheduleItem item = b.getScheduleItem();


        scheduledBreakRepository.delete(b);
        if (item != null) scheduledItemRepository.delete(item);
    }
}