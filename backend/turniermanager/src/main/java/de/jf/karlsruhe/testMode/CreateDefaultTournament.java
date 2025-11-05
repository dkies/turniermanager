package de.jf.karlsruhe.testMode;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.repos.*;
import de.jf.karlsruhe.service.GamePlanGeneratorService; // NEU: Der Generator-Service
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order; // Optional: Steuert die Ausführungsreihenfolge

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

@Configuration
//@Order(10) // Führt diesen Code nach der RoundRobinTestConfiguration aus (falls vorhanden)
public class CreateDefaultTournament {

    // Wir entfernen die manuelle Erstellung von ScheduledGame/Break, da der Service das jetzt übernimmt.
    @Bean
    CommandLineRunner initData(
            TournamentRepository tournamentRepository,
            AgeGroupRepository ageGroupRepository,
            RoundRepository roundRepository,
            PitchRepository pitchRepository,
            TeamRepository teamRepository,
            LeagueRepository leagueRepository,
            // ScheduleItemRepository scheduleItemRepository, // Nicht mehr direkt benötigt
            // ScheduledBreakRepository scheduledBreakRepository, // Nicht mehr direkt benötigt
            GamePlanGeneratorService gamePlanGeneratorService // <--- DER WICHTIGE NEUE SERVICE
    ) {
        return args -> {

            System.out.println("\n--- Starte Turnier-Datenaufbau und GamePlanGenerator ---");

            // --- 1. Basis-Setup (Teams, Pitches, Settings) ---
            AgeGroup u17 = ageGroupRepository.save(AgeGroup.builder().name("U17").build());

            // Tournament mit Startzeit und Spieldauer-Einstellungen
            LocalDateTime tournamentStart = LocalDateTime.of(2026, 7, 1, 9, 0);
            Tournament sommerCup = tournamentRepository.save(Tournament.builder()
                    .name("Sommer Cup 2026")
                    .startTime(tournamentStart) // Die Startzeit für den Scheduler
                    .playTime(15) // 15 Minuten Spielzeit
                    .breakTime(5)  // 5 Minuten Übergangszeit zwischen Spielen
                    .venue("Musterstadt")
                    .build());
            System.out.println("Gespeichert: Tournament " + sommerCup.getName() + " mit Startzeit und Settings.");

            Round gruppenphase = roundRepository.save(Round.builder().name("Gruppenphase").orderIndex(1).tournament(sommerCup).build());

            Pitch platzA = pitchRepository.save(Pitch.builder().name("Platz A").ageGroup(u17).build());
            Pitch platzB = pitchRepository.save(Pitch.builder().name("Platz B").ageGroup(u17).build());
            System.out.println("Gespeichert: 2 Pitches für U17.");

            Team team1 = teamRepository.save(Team.builder().name("Adler Karlsruhe").ageGroup(u17).build());
            Team team2 = teamRepository.save(Team.builder().name("Tiger Stuttgart").ageGroup(u17).build());
            Team team3 = teamRepository.save(Team.builder().name("Bären Berlin").ageGroup(u17).build());
            Team team4 = teamRepository.save(Team.builder().name("Löwen München").ageGroup(u17).build());
            Team team5 = teamRepository.save(Team.builder().name("Fuchs Hamburg").ageGroup(u17).build());
            System.out.println("Gespeichert: 5 Teams (Ungerade Zahl für Test der Spielfrei-Runden).");


            // --- 2. Ligen (Gruppen) erstellen ---

            // Liga mit 5 Teams (für Test der ungeraden Anzahl)
            League gruppeA = League.builder()
                    .name("Gruppe A (U17)")
                    .isQualification(true)
                    .tournament(sommerCup)
                    .ageGroup(u17)
                    .round(gruppenphase)
                    .teams(Arrays.asList(team1, team2, team3, team4, team5))
                    .build();
            leagueRepository.save(gruppeA);

            System.out.println("Gespeichert: 1 Liga mit 5 Teams.");


            // --- 3. Optional: Eine globale Pause für den Testfall einfügen ---
            // Wir fügen eine Pause ein, um zu prüfen, ob der Scheduler diese umgeht.

            // Wir müssen ScheduleItemRepository injecten, um die Pause zu speichern:
            // Da wir ScheduleItemRepository oben auskommentiert haben, verwenden wir hier
            // eine vereinfachte Injektion oder fügen das Repo oben wieder hinzu.
            // FÜR DIESEN FALL füge ich ScheduleItemRepository wieder hinzu:
            // HINWEIS: Sie müssen ScheduleItemRepository oben im initData-Methodenkopf wieder einkommentieren!

            /*
            ScheduleItemRepository scheduleItemRepository = context.getBean(ScheduleItemRepository.class);
            LocalDateTime pauseStart = LocalDateTime.of(2026, 7, 1, 10, 0); // 10:00 Uhr

            ScheduleItem breakItem = ScheduleItem.builder()
                    .ageGroup(u17) // Kann auch null sein für global
                    .itemType("BREAK")
                    .startTime(pauseStart)
                    .endTime(pauseStart.plusMinutes(60)) // 1 Stunde Pause
                    .scheduledPitch(null) // Global
                    .build();
            scheduleItemRepository.save(breakItem);

            System.out.println("Gespeichert: Globale Pause von 10:00 bis 11:00 Uhr.");
            */


            // --- 4. Ausführung der Spielplan-Generierung ---

            System.out.println("\n--- Starte GamePlanGeneratorService: Spiele werden generiert... ---");
            gamePlanGeneratorService.generateScheduleForLeague(gruppeA, sommerCup);

            System.out.println("✅ Spielplan für " + gruppeA.getName() + " erfolgreich generiert und gespeichert!");
            System.out.println("--- DB-Initialisierung abgeschlossen. ---\n");
        };
    }
}