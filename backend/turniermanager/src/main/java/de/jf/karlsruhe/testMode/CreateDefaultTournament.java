package de.jf.karlsruhe.testMode;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.enums.RoundType;
import de.jf.karlsruhe.model.repos.*;
import de.jf.karlsruhe.service.GamePlanGeneratorService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.LocalDateTime;
import java.util.Arrays;

@Configuration
//@Order(10)
public class CreateDefaultTournament {

    @Bean
    CommandLineRunner initData(
            TournamentRepository tournamentRepository,
            AgeGroupRepository ageGroupRepository,
            RoundRepository roundRepository,
            PitchRepository pitchRepository,
            TeamRepository teamRepository,
            LeagueRepository leagueRepository,
            GamePlanGeneratorService gamePlanGeneratorService
    ) {
        return args -> {

            System.out.println("\n--- Starte Turnier-Datenaufbau und GamePlanGenerator ---");

            // --- 1. Basis-Setup (Teams, Pitches, Settings) ---

            // Tournament und Round sind für beide Altersgruppen gleich
            LocalDateTime tournamentStart = LocalDateTime.of(2026, 7, 1, 9, 0);
            Tournament sommerCup = tournamentRepository.save(Tournament.builder()
                    .name("Sommer Cup 2026")
                    .startTime(tournamentStart)
                    .playTimeInSeconds(600) // 10 Minuten Spielzeit
                    .breakTimeInSeconds(300)  // 5 Minuten Pause
                    .venue("Musterstadt")
                    .build());
            System.out.println("Gespeichert: Tournament " + sommerCup.getName() + ".");

            Round gruppenphase = roundRepository.save(Round.builder().name("Gruppenphase").orderIndex(1).roundType(RoundType.QUALIFICATION).tournament(sommerCup).build());


            // -----------------------------------------------------------
            // A) SETUP FÜR U17
            // -----------------------------------------------------------
            AgeGroup u17 = ageGroupRepository.save(AgeGroup.builder().name("U17").build());
            System.out.println("Gespeichert: AgeGroup U17.");

            Pitch platzA = pitchRepository.save(Pitch.builder().name("Platz A").ageGroup(u17).build());
            Pitch platzB = pitchRepository.save(Pitch.builder().name("Platz B").ageGroup(u17).build());
            System.out.println("Gespeichert: 2 Pitches für U17 (Platz A, Platz B).");

            Team team1 = teamRepository.save(Team.builder().name("Adler Karlsruhe").ageGroup(u17).build());
            Team team2 = teamRepository.save(Team.builder().name("Tiger Stuttgart").ageGroup(u17).build());
            Team team3 = teamRepository.save(Team.builder().name("Bären Berlin").ageGroup(u17).build());
            Team team4 = teamRepository.save(Team.builder().name("Löwen München").ageGroup(u17).build());
            Team team5 = teamRepository.save(Team.builder().name("Fuchs Hamburg").ageGroup(u17).build());
            System.out.println("Gespeichert: 5 Teams für U17.");

            League gruppeA = League.builder()
                    .name("Gruppe A (U17)")
                    .isQualification(true)
                    .tournament(sommerCup)
                    .ageGroup(u17)
                    .round(gruppenphase)
                    .teams(Arrays.asList(team1, team2, team3, team4, team5))
                    .build();
            leagueRepository.save(gruppeA);
            System.out.println("Gespeichert: 1 Liga (Gruppe A) für U17.");

            // -----------------------------------------------------------
            // B) SETUP FÜR U13 (NEU)
            // -----------------------------------------------------------
            AgeGroup u13 = ageGroupRepository.save(AgeGroup.builder().name("U13").build());
            System.out.println("Gespeichert: AgeGroup U13.");

            Pitch platzC = pitchRepository.save(Pitch.builder().name("Platz C").ageGroup(u13).build());
            Pitch platzD = pitchRepository.save(Pitch.builder().name("Platz D").ageGroup(u13).build());
            System.out.println("Gespeichert: 2 Pitches für U13 (Platz C, Platz D).");

            Team team6 = teamRepository.save(Team.builder().name("Mäuse Offenburg").ageGroup(u13).build());
            Team team7 = teamRepository.save(Team.builder().name("Eulen Freiburg").ageGroup(u13).build());
            Team team8 = teamRepository.save(Team.builder().name("Rehe Pforzheim").ageGroup(u13).build());
            Team team9 = teamRepository.save(Team.builder().name("Katz Karlsruhe").ageGroup(u13).build());
            Team team10 = teamRepository.save(Team.builder().name("Hund Baden-Baden").ageGroup(u13).build());
            System.out.println("Gespeichert: 5 Teams für U13.");

            League gruppeB_U13 = League.builder()
                    .name("Gruppe B (U13)")
                    .isQualification(true)
                    .tournament(sommerCup)
                    .ageGroup(u13) // Wichtig: U13 AgeGroup zuweisen
                    .round(gruppenphase)
                    .teams(Arrays.asList(team6, team7, team8, team9, team10))
                    .build();
            leagueRepository.save(gruppeB_U13);
            System.out.println("Gespeichert: 1 Liga (Gruppe B) für U13.");

            // -----------------------------------------------------------
            // 4. Ausführung der Spielplan-Generierung
            // -----------------------------------------------------------

            System.out.println("\n--- Starte GamePlanGeneratorService: U17 Spiele werden generiert... ---");
            gamePlanGeneratorService.generateScheduleForLeague(gruppeA, sommerCup);
            System.out.println("✅ Spielplan für " + gruppeA.getName() + " erfolgreich generiert und gespeichert!");

            System.out.println("\n--- Starte GamePlanGeneratorService: U13 Spiele werden generiert... ---");
            gamePlanGeneratorService.generateScheduleForLeague(gruppeB_U13, sommerCup);
            System.out.println("✅ Spielplan für " + gruppeB_U13.getName() + " erfolgreich generiert und gespeichert!");

            System.out.println("--- DB-Initialisierung abgeschlossen. ---\n");
        };
    }
}