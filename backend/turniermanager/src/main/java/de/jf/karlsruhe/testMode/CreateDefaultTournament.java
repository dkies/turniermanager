package de.jf.karlsruhe.testMode;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.repos.*;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

@Configuration
public class CreateDefaultTournament {

    @Bean
    CommandLineRunner initData(
            TournamentRepository tournamentRepository,
            AgeGroupRepository ageGroupRepository,
            RoundRepository roundRepository,
            PitchRepository pitchRepository,
            TeamRepository teamRepository,
            LeagueRepository leagueRepository,
            ScheduleItemRepository scheduleItemRepository,    // NEU: Für den Planungs-Header
            ScheduledGameRepository scheduledGameRepository,
            ScheduledBreakRepository scheduledBreakRepository
    ) {
        return args -> {

            System.out.println("--- Starte Turnier-Datenaufbau mit Komposition ---");

            // 1. Basisdaten erstellen
            AgeGroup u17 = ageGroupRepository.save(AgeGroup.builder().name("U17").build());
            System.out.println("Gespeichert: AgeGroup " + u17.getName());

            Tournament sommerCup = tournamentRepository.save(Tournament.builder()
                    .name("Sommer Cup 2026").startDate(LocalDate.of(2026, 7, 1)).venue("Musterstadt").build());
            System.out.println("Gespeichert: Tournament " + sommerCup.getName());

            Round gruppenphase = roundRepository.save(Round.builder().name("Gruppenphase").orderIndex(1).tournament(sommerCup).build());
            System.out.println("Gespeichert: Round " + gruppenphase.getName());

            Pitch platzA = pitchRepository.save(Pitch.builder().name("Platz A").ageGroup(u17).build());
            Pitch platzB = pitchRepository.save(Pitch.builder().name("Platz B").ageGroup(u17).build());
            List<Pitch> pitches = Arrays.asList(platzA, platzB);
            System.out.println("Gespeichert: " + pitches.size() + " Pitches.");

            Team team1 = teamRepository.save(Team.builder().name("Adler Karlsruhe U17").ageGroup(u17).build());
            Team team2 = teamRepository.save(Team.builder().name("Tiger Stuttgart U17").ageGroup(u17).build());
            Team team3 = teamRepository.save(Team.builder().name("Bären Berlin U17").ageGroup(u17).build());
            Team team4 = teamRepository.save(Team.builder().name("Löwen München U17").ageGroup(u17).build());
            System.out.println("Gespeichert: 4 Teams.");

            // 2. Ligen (Gruppen) erstellen (zwei Ligen in einer Runde)
            League gruppeA = League.builder()
                    .name("Gruppe A").isQualification(true).tournament(sommerCup).ageGroup(u17).round(gruppenphase)
                    .teams(Arrays.asList(team1, team2)).build();
            leagueRepository.save(gruppeA);

            League gruppeB = League.builder()
                    .name("Gruppe B").isQualification(true).tournament(sommerCup).ageGroup(u17).round(gruppenphase)
                    .teams(Arrays.asList(team3, team4)).build();
            leagueRepository.save(gruppeB);
            System.out.println("Gespeichert: 2 Ligen in Runde " + gruppenphase.getName());


            // --- 3. Planungseintrag für GLOBALE Pause erstellen ---

            LocalDateTime pauseStart = LocalDateTime.of(2026, 7, 1, 12, 0);

            // A. ScheduleItem (Header) erstellen: KEIN Pitch (null), da GLOBAL!
            ScheduleItem breakItem = ScheduleItem.builder()
                    .ageGroup(u17)
                    .itemType("BREAK")
                    .startTime(pauseStart)
                    .endTime(pauseStart.plusMinutes(60))
                    .scheduledPitch(null)
                    .build();
            breakItem = scheduleItemRepository.save(breakItem);

            // B. ScheduledBreak (Detail) erstellen und mit Header verknüpfen
            ScheduledBreak mittagspause = ScheduledBreak.builder()
                    .message("Mittagspause")
                    .scheduleItem(breakItem) // OneToOne Verknüpfung
                    .build();
            scheduledBreakRepository.save(mittagspause);
            System.out.println("Gespeichert: Globale Pause (Start: " + breakItem.getStartTime() + ")");

            // --- 4. Planungseinträge für SPIELE erstellen ---

            LocalDateTime gameStart1 = LocalDateTime.of(2026, 7, 1, 9, 0);

            // Spiel 1: Vor der Pause auf Platz A
            // A. ScheduleItem (Header) erstellen. MIT Pitch-Zuordnung!
            ScheduleItem gameItem1 = ScheduleItem.builder()
                    .ageGroup(u17)
                    .itemType("GAME")
                    .startTime(gameStart1)
                    .endTime(gameStart1.plusMinutes(20))
                    .scheduledPitch(platzA)
                    .build();
            gameItem1 = scheduleItemRepository.save(gameItem1);

            // B. ScheduledGame (Detail) erstellen
            ScheduledGame game1 = ScheduledGame.builder()
                    .teamA(team1).teamB(team2)
                    .teamAScore(1).teamBScore(1)
                    .scheduleItem(gameItem1)
                    .build();
            scheduledGameRepository.save(game1);

            // Spiel 2: Nach der Pause auf Platz B
            // A. ScheduleItem (Header) erstellen. MIT Pitch-Zuordnung!
            ScheduleItem gameItem2 = ScheduleItem.builder()
                    .ageGroup(u17)
                    .itemType("GAME")
                    .startTime(mittagspause.getScheduleItem().getEndTime()) // Startet nach der Pause
                    .endTime(mittagspause.getScheduleItem().getEndTime().plusMinutes(20))
                    .scheduledPitch(platzB)
                    .build();
            gameItem2 = scheduleItemRepository.save(gameItem2);

            // B. ScheduledGame (Detail) erstellen
            ScheduledGame game2 = ScheduledGame.builder()
                    .teamA(team3).teamB(team4)
                    .teamAScore(3).teamBScore(0)
                    .scheduleItem(gameItem2)
                    .build();
            scheduledGameRepository.save(game2);

            System.out.println("Gespeichert: 2 Scheduled Games.");

            System.out.println("--- DB-Struktur mit Komposition erfolgreich getestet. ---");
        };
    }
}