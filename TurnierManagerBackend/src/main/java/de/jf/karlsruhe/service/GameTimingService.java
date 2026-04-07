package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.AgeGroup;
import de.jf.karlsruhe.model.base.Pitch;
import de.jf.karlsruhe.model.base.ScheduleItem;
import de.jf.karlsruhe.model.base.Tournament;
import de.jf.karlsruhe.model.enums.GameStatus;
import de.jf.karlsruhe.model.enums.ScheduledItemType;
import de.jf.karlsruhe.model.repos.ScheduledItemRepository;
import de.jf.karlsruhe.model.repos.TournamentRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class GameTimingService {

    private final ScheduledItemRepository scheduledItemRepository;
    private final TournamentRepository tournamentRepository;

    @Transactional
    public void finishAllItemsAtTime(LocalDateTime plannedStartTime, LocalDateTime actualEndTime) {
        // 1. Suche exakt die Items mit dieser Startzeit
        List<ScheduleItem> itemsAtTime = scheduledItemRepository.findAll().stream()
                .filter(item -> item.getStartTime().equals(plannedStartTime))
                .filter(item -> item.getStatus() != GameStatus.COMPLETED)
                .filter(item -> item.getStatus() != GameStatus.COMPLETED_AND_STATED)
                .toList();

        if (itemsAtTime.isEmpty()) {
            System.out.println("Keine geplanten Spiele/Pausen für exakt " + plannedStartTime + " gefunden.");
            return;
        }

        // 2. Diese Items als erledigt markieren
        for (ScheduleItem item : itemsAtTime) {
            item.setStatus(GameStatus.COMPLETED);
            item.setEndTime(actualEndTime);
            scheduledItemRepository.save(item);
        }

        // 3. Den restlichen Plan ab dieser Zeit "glattziehen"
        refreshGlobalSchedule(plannedStartTime, actualEndTime);
    }

    private void refreshGlobalSchedule(LocalDateTime plannedStartTime, LocalDateTime actualEndTime) {
        // 1. Berechne den Delay basierend auf dem geplanten Slot und dem realen Ende
        // WICHTIG: Wenn wir um 20:43 fertig sind, das Spiel aber um 16:45 startete,
        // ist der Versatz die Zeit von 16:45 bis 20:43.
        Tournament tournament = tournamentRepository.findAll().getFirst();
        Duration delay = Duration.between(plannedStartTime, actualEndTime).minusSeconds(tournament.getPlayTimeInSeconds());

        // Aufrunden auf volle Minuten, um "krumme" Sekunden zu vermeiden
        long seconds = delay.getSeconds();
        long roundedMinutes = (long) Math.ceil(seconds / 60.0);
        Duration roundedDelay = Duration.ofMinutes(roundedMinutes);

        System.out.println(roundedMinutes);
        List<ScheduleItem> allUpcoming = scheduledItemRepository.findAll().stream()
                .filter(item -> item.getStatus() == GameStatus.SCHEDULED)
                .toList();

        for (ScheduleItem item : allUpcoming) {
            // Die ursprüngliche Dauer des Items (egal ob Game oder Break!)
            Duration originalDuration = Duration.between(item.getStartTime(), item.getEndTime());

            // Neuer Start = Alter Start + Versatz (sauber auf Minute)
            LocalDateTime newStart = item.getStartTime().plus(roundedDelay).withSecond(0).withNano(0);

            // Neues Ende = Neuer Start + ursprüngliche Dauer
            // So bleibt eine 5-Minuten-Pause eine 5-Minuten-Pause
            // und ein 10-Minuten-Spiel ein 10-Minuten-Spiel.
            LocalDateTime newEnd = newStart.plus(originalDuration);

            item.setStartTime(newStart);
            item.setEndTime(newEnd);
        }

        scheduledItemRepository.saveAll(allUpcoming);
    }


    /**
     * Verschiebt alle Items, die nach (oder genau zu) einem Zeitpunkt starten.
     */
    @Transactional
    public void shiftAllAfter(LocalDateTime threshold, long minutes, AgeGroup ageGroup) {
        List<ScheduleItem> items = scheduledItemRepository.findByAgeGroupAndStartTimeIsAfter(ageGroup, threshold.minusSeconds(1));
        items.forEach(item -> item.shiftTime(minutes));
        scheduledItemRepository.saveAll(items);
    }

    /**
     * Verschiebt alle Items, die vor einem Zeitpunkt starten.
     */
    @Transactional
    public void shiftAllBefore(LocalDateTime threshold, long minutes, AgeGroup ageGroup) {
        List<ScheduleItem> items = scheduledItemRepository.findByAgeGroupAndStartTimeIsBefore(ageGroup, threshold);
        items.forEach(item -> item.shiftTime(minutes));
        scheduledItemRepository.saveAll(items);
    }

    /**
     * Tauscht die Zeitfenster (Start, Ende und Platz) zwischen zwei Items.
     */
    @Transactional
    public void swapTimes(UUID idA, UUID idB) {
        ScheduleItem itemA = scheduledItemRepository.findById(idA)
                .orElseThrow(() -> new IllegalArgumentException("Item A nicht gefunden"));
        ScheduleItem itemB = scheduledItemRepository.findById(idB)
                .orElseThrow(() -> new IllegalArgumentException("Item B nicht gefunden"));

        // Temporäres Backup der Zeiten von A
        LocalDateTime tempStart = itemA.getStartTime();
        LocalDateTime tempEnd = itemA.getEndTime();
        Pitch tempPitch = itemA.getScheduledPitch();

        // A bekommt die Zeiten von B
        itemA.setStartTime(itemB.getStartTime());
        itemA.setEndTime(itemB.getEndTime());
        itemA.setScheduledPitch(itemB.getScheduledPitch());

        // B bekommt die alten Zeiten von A
        itemB.setStartTime(tempStart);
        itemB.setEndTime(tempEnd);
        itemB.setScheduledPitch(tempPitch);

        scheduledItemRepository.saveAll(List.of(itemA, itemB));
    }

    /**
     * GLOBAL: Verschiebt ALLE Items im gesamten Turnier, die nach (oder genau zu)
     * einem Zeitpunkt starten, um x Minuten.
     */
    @Transactional
    public void shiftAllGlobalAfter(LocalDateTime threshold, long minutes) {
        // Wir holen alle Items ab dem Zeitpunkt, egal welche Altersgruppe oder Liga
        List<ScheduleItem> items = scheduledItemRepository.findByStartTimeIsAfter(threshold.minusSeconds(1));

        items.forEach(item -> item.shiftTime(minutes));

        scheduledItemRepository.saveAll(items);
    }

    /**
     * GLOBAL: Verschiebt ALLE Items im gesamten Turnier, die vor einem
     * Zeitpunkt starten.
     */
    @Transactional
    public void shiftAllGlobalBefore(LocalDateTime threshold, long minutes) {
        List<ScheduleItem> items = scheduledItemRepository.findByStartTimeIsBefore(threshold);

        items.forEach(item -> item.shiftTime(minutes));

        scheduledItemRepository.saveAll(items);
    }
}