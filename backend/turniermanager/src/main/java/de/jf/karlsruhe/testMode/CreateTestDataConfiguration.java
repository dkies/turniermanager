package de.jf.karlsruhe.testMode;

import de.jf.karlsruhe.model.base.*;
import de.jf.karlsruhe.model.enums.GameStatus;
import de.jf.karlsruhe.model.enums.RoundType;
import de.jf.karlsruhe.model.repos.*;
import de.jf.karlsruhe.service.GamePlanGeneratorService;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order; // WICHTIG: Stellt sicher, dass dieses Setup zuerst läuft
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Random;
import java.util.UUID;

@Configuration
@Order(1) // Sorgt dafür, dass dieses Setup vor der Ranglisten-Evaluierung läuft
public class CreateTestDataConfiguration {

    // Zufallsgenerator für die Punktestände
    private static final Random RANDOM = new Random();

    // ***************************************************************
    // SERVICE: Schließt Spiele in einer Transaktion ab (MUSS @Transactional sein)
    // ***************************************************************
    @Bean
    @Transactional
    public DataCompletionService dataCompletionService(ScheduledGameRepository scheduledGameRepository) {
        return new DataCompletionService(scheduledGameRepository);
    }

    // Innere Klasse/Record für den Service (oder als eigene Datei)
    // Wir verwenden hier eine innere Klasse für die Einfachheit
    public record DataCompletionService(ScheduledGameRepository scheduledGameRepository) {
        public void completeGamesRandomly(League league) {

            List<ScheduledGame> plannedGames = scheduledGameRepository.findGamesByLeagueIdAndStatus(
                    league.getId(), GameStatus.SCHEDULED);

            System.out.printf("    -> Schließe %d Spiele in %s mit Zufallsergebnissen ab...\n", plannedGames.size(), league.getName());

            for (ScheduledGame game : plannedGames) {
                // Generiere zufällige Punktzahlen (0-5)
                int scoreA = RANDOM.nextInt(6);
                int scoreB = RANDOM.nextInt(6);

                game.setTeamAScore(scoreA);
                game.setTeamBScore(scoreB);
                game.setStatus(GameStatus.COMPLETED);

                // Speichert die geänderten Spiele
                scheduledGameRepository.save(game);
            }
            // Transaktion wird hier committed, die Daten sind in der DB
            System.out.printf("    -> Alle Spiele für %s wurden erfolgreich committed.\n", league.getName());
        }
    }

    // ***************************************************************
    // COMMAND LINE RUNNER: Führt das Setup aus
    // ***************************************************************
    @Bean
    CommandLineRunner initData(
            TournamentRepository tournamentRepository,
            AgeGroupRepository ageGroupRepository,
            RoundRepository roundRepository,
            PitchRepository pitchRepository,
            TeamRepository teamRepository,
            LeagueRepository leagueRepository,
            GamePlanGeneratorService gamePlanGeneratorService,
            DataCompletionService dataCompletionService // NEU: Inject des Completion Service
    ) {
        return args -> {

            System.out.println("\n--- 1. Starte Turnier-Datenaufbau (Phase 1/2) ---");

            // --- SETUP CODE ---
            LocalDateTime tournamentStart = LocalDateTime.of(2026, 7, 1, 9, 0);
            Tournament sommerCup = tournamentRepository.save(Tournament.builder().name("Sommer Cup 2026").startTime(tournamentStart).playTimeInSeconds(600).breakTimeInSeconds(300).build());
            Round gruppenphase = roundRepository.save(Round.builder().name("Gruppenphase").orderIndex(1).roundType(RoundType.QUALIFICATION).tournament(sommerCup).build());

            // A) SETUP FÜR U17
            AgeGroup u17 = ageGroupRepository.save(AgeGroup.builder().name("U17").build());
            Pitch platzA = pitchRepository.save(Pitch.builder().name("Platz A").ageGroup(u17).build());
            Pitch platzB = pitchRepository.save(Pitch.builder().name("Platz B").ageGroup(u17).build());
            Team team1 = teamRepository.save(Team.builder().name("Adler Karlsruhe").ageGroup(u17).build());
            Team team2 = teamRepository.save(Team.builder().name("Tiger Stuttgart").ageGroup(u17).build());
            Team team3 = teamRepository.save(Team.builder().name("Bären Berlin").ageGroup(u17).build());
            Team team4 = teamRepository.save(Team.builder().name("Löwen München").ageGroup(u17).build());
            Team team5 = teamRepository.save(Team.builder().name("Fuchs Hamburg").ageGroup(u17).build());
            League gruppeA = leagueRepository.save(League.builder().name("Gruppe A (U17)").isQualification(true).tournament(sommerCup).ageGroup(u17).round(gruppenphase).teams(Arrays.asList(team1, team2, team3, team4, team5)).build());

            // B) SETUP FÜR U13
            AgeGroup u13 = ageGroupRepository.save(AgeGroup.builder().name("U13").build());
            Pitch platzC = pitchRepository.save(Pitch.builder().name("Platz C").ageGroup(u13).build());
            Pitch platzD = pitchRepository.save(Pitch.builder().name("Platz D").ageGroup(u13).build());
            Team team6 = teamRepository.save(Team.builder().name("Mäuse Offenburg").ageGroup(u13).build());
            Team team7 = teamRepository.save(Team.builder().name("Eulen Freiburg").ageGroup(u13).build());
            Team team8 = teamRepository.save(Team.builder().name("Rehe Pforzheim").ageGroup(u13).build());
            Team team9 = teamRepository.save(Team.builder().name("Katz Karlsruhe").ageGroup(u13).build());
            Team team10 = teamRepository.save(Team.builder().name("Hund Baden-Baden").ageGroup(u13).build());
            League gruppeB_U13 = leagueRepository.save(League.builder().name("Gruppe B (U13)").isQualification(true).tournament(sommerCup).ageGroup(u13).round(gruppenphase).teams(Arrays.asList(team6, team7, team8, team9, team10)).build());

            // 4. Ausführung der Spielplan-Generierung
            gamePlanGeneratorService.generateScheduleForLeague(gruppeA, sommerCup);
            gamePlanGeneratorService.generateScheduleForLeague(gruppeB_U13, sommerCup);

            // 5. TEST DATEN ERSTELLEN: ZUFÄLLIGE ERGEBNISSE EINTRAGEN (WIRD ÜBER DEN TRANSAKTIONALEN SERVICE GEMACHT)
            System.out.println("\n--- Zufallsergebnisse werden eingetragen (Transaktion Phase) ---");
            dataCompletionService.completeGamesRandomly(gruppeA);
            //dataCompletionService.completeGamesRandomly(gruppeB_U13);
        };
    }

}