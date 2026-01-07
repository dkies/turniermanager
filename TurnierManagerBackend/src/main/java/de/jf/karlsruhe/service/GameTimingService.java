package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.Pitch;
import de.jf.karlsruhe.model.base.ScheduleItem;
import de.jf.karlsruhe.model.base.Tournament;
import de.jf.karlsruhe.model.enums.GameStatus;
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
}