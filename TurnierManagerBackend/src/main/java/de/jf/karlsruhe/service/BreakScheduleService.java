package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.dto.BreakGlobalCreationDTO;
import de.jf.karlsruhe.model.dto.BreakSingleCreationDTO;
import de.jf.karlsruhe.model.enums.GameStatus;
import de.jf.karlsruhe.model.enums.ScheduledItemType;
import de.jf.karlsruhe.model.repos.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

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

        return executeBreakCreation(Collections.singletonList(ageGroup), dto.startTime(), dto.amountOfBreaks(), dto.message());
    }

    @Transactional
    public List<ScheduledBreak> setBreakForAllAgeGroups(BreakGlobalCreationDTO dto) {
        return executeBreakCreation(ageGroupRepository.findAll(), dto.startTime(), dto.amountOfBreaks(), dto.message());
    }

    private List<ScheduledBreak> executeBreakCreation(List<AgeGroup> groups, LocalDateTime desiredStart, int count, String msg) {
        Tournament t = tournamentRepository.findAll().getFirst();
        List<Pitch> allTournamentPitches = pitchRepository.findAll();

        // 1. Den exakten Slot finden (Sync über alle Plätze + Raster-Einrastung)
        LocalDateTime actualStart = calculateActualStart(allTournamentPitches, desiredStart, t);

        // 2. Globaler Shift: Platz schaffen für alle zukünftigen Spiele im Turnier
        long slotDuration = t.getPlayTimeInSeconds() + t.getBreakTimeInSeconds();
        shiftFutureItems(actualStart, count * slotDuration, groups);

        // 3. Pausen-Entitäten für die betroffenen Gruppen anlegen
        List<ScheduledBreak> createdBreaks = new ArrayList<>();
        for (AgeGroup group : groups) {
            List<Pitch> groupPitches = pitchRepository.findByAgeGroup(group);
            createdBreaks.addAll(createBreakItems(groupPitches, actualStart, count, msg, group, t));
        }
        return createdBreaks;
    }

    private LocalDateTime calculateActualStart(List<Pitch> pitches, LocalDateTime desiredStart, Tournament t) {
        LocalDateTime latestEnd = desiredStart;

        // 1. Sync-Punkt: Wir nutzen eine normale Schleife, um latestEnd zu aktualisieren
        for (Pitch p : pitches) {
            Optional<ScheduleItem> runningGame = scheduledItemRepository
                    .findFirstByScheduledPitchAndStartTimeBeforeAndEndTimeAfter(p, latestEnd, latestEnd);

            if (runningGame.isPresent()) {
                LocalDateTime gameEnd = runningGame.get().getEndTime();
                if (gameEnd.isAfter(latestEnd)) {
                    latestEnd = gameEnd;
                }
            }
        }

        // 2. Raster-Einrasten: Den nächsten Slot-Start finden
        return scheduledItemRepository.findFirstByEndTimeIsAfterOrderByStartTimeAsc(latestEnd)
                .map(ScheduleItem::getStartTime)
                .orElse(latestEnd);
    }

    private void shiftFutureItems(LocalDateTime startTime, long seconds, List<AgeGroup> groups) {
        List<ScheduleItem> items = scheduledItemRepository.findByStartTimeIsAfter(startTime.minusSeconds(1)).stream().filter(item -> groups.contains(item.getAgeGroup())).collect(Collectors.toList());
        items.forEach(item -> {
            item.setStartTime(item.getStartTime().plusSeconds(seconds));
            item.setEndTime(item.getEndTime().plusSeconds(seconds));
        });
        scheduledItemRepository.saveAll(items);
    }

    private List<ScheduledBreak> createBreakItems(List<Pitch> pitches, LocalDateTime start, int count, String msg, AgeGroup group, Tournament t) {
        List<ScheduledBreak> result = new ArrayList<>();
        long slotTotal = t.getPlayTimeInSeconds() + t.getBreakTimeInSeconds();

        for (Pitch pitch : pitches) {
            for (int i = 0; i < count; i++) {
                LocalDateTime pStart = start.plusSeconds(i * slotTotal);
                ScheduleItem item = scheduledItemRepository.save(ScheduleItem.builder()
                        .startTime(pStart).endTime(pStart.plusSeconds(t.getPlayTimeInSeconds()))
                        .itemType(ScheduledItemType.BREAK).scheduledPitch(pitch).ageGroup(group)
                        .status(GameStatus.SCHEDULED).build());

                result.add(scheduledBreakRepository.save(new ScheduledBreak(null, msg, item)));
            }
        }
        return result;
    }

    @Transactional
    public void deleteBreak(UUID breakId) {
        ScheduledBreak b = scheduledBreakRepository.findById(breakId).orElseThrow();
        ScheduleItem item = b.getScheduleItem();

        scheduledBreakRepository.delete(b);
        if (item != null) scheduledItemRepository.delete(item);
    }
}