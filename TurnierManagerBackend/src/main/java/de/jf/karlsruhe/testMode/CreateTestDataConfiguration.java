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
import java.util.*;

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
    public DataCompletionService dataCompletionService(ScheduledGameRepository scheduledGameRepository, ScheduledItemRepository scheduledItemRepository) {
        return new DataCompletionService(scheduledGameRepository, scheduledItemRepository);
    }

    // Innere Klasse/Record für den Service (oder als eigene Datei)
    // Wir verwenden hier eine innere Klasse für die Einfachheit
    public record DataCompletionService(ScheduledGameRepository scheduledGameRepository,
                                        ScheduledItemRepository scheduledItemRepository) {
        public void completeGamesRandomly(League league) {

            List<ScheduledGame> plannedGames = scheduledGameRepository.findAll().stream()
                    .filter(g -> g.getScheduleItem().getLeague() != null &&
                            g.getScheduleItem().getLeague().getId().equals(league.getId()))
                    .toList();

            System.out.printf("    -> Schließe %d Spiele in %s mit Zufallsergebnissen ab...\n", plannedGames.size(), league.getName());

            for (ScheduledGame game : plannedGames) {
                // Generiere zufällige Punktzahlen (0-5)
                int scoreA = RANDOM.nextInt(6);
                int scoreB = RANDOM.nextInt(6);

                game.setTeamAScore(scoreA);
                game.setTeamBScore(scoreB);
                ScheduleItem scheduleItem = game.getScheduleItem();
                scheduleItem.setStatus(GameStatus.COMPLETED);

                // Speichert die geänderten Spiele
                scheduledGameRepository.save(game);
                scheduledItemRepository.save(scheduleItem);
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
            LocalDateTime tournamentStart = LocalDateTime.of(2026, 1, 7, 13, 0);
            Tournament sommerCup = tournamentRepository.save(Tournament.builder().name("Sommer Cup 2026").startTime(tournamentStart).playTimeInSeconds(600).breakTimeInSeconds(300).build());
            Round gruppenphase = roundRepository.save(Round.builder().name("Gruppenphase").orderIndex(1).roundType(RoundType.QUALIFICATION).tournament(sommerCup).build());

// --- SETUP FÜR U17 ---
            AgeGroup u17 = ageGroupRepository.save(AgeGroup.builder().name("U17").build());
            Pitch platzA = pitchRepository.save(Pitch.builder().name("Platz A").ageGroup(u17).build());
            Pitch platzB = pitchRepository.save(Pitch.builder().name("Platz B").ageGroup(u17).build());

            List<String> u17Names = Arrays.asList(
                    "Adler Karlsruhe", "Tiger Stuttgart", "Bären Berlin", "Löwen München",
                    "Fuchs Hamburg", "Wölfe Wolfsburg", "Haie Köln", "Eisbären Regensburg",
                    "Panther Augsburg", "Wildcats Mannheim", "Bussarde Ettlingen", "Luchse Bruchsal"
            );

            List<Team> u17Teams = new ArrayList<>();
            for (String name : u17Names) {
                u17Teams.add(teamRepository.save(Team.builder().name(name).ageGroup(u17).build()));
            }

            // Aufteilung auf zwei Gruppen à 6 Teams
            League gruppeA_U17 = leagueRepository.save(League.builder()
                    .name("Gruppe A (U17)").tournament(sommerCup).ageGroup(u17).round(gruppenphase)
                    .teams(new ArrayList<>(u17Teams.subList(0, 12))).build());




// --- SETUP FÜR U13 ---
            AgeGroup u13 = ageGroupRepository.save(AgeGroup.builder().name("U13").build());
            Pitch platzC = pitchRepository.save(Pitch.builder().name("Platz C").ageGroup(u13).build());
            Pitch platzD = pitchRepository.save(Pitch.builder().name("Platz D").ageGroup(u13).build());

            List<String> u13Names = Arrays.asList(
                    "Mäuse Offenburg", "Eulen Freiburg", "Rehe Pforzheim", "Katz Karlsruhe",
                    "Hund Baden-Baden", "Igel Rastatt", "Eichhörnchen Landau", "Dachse Speyer",
                    "Hasen Kehl", "Marder Durlach", "Hamster Grötzingen", "Biber Eggenstein"
            );

            List<Team> u13Teams = new ArrayList<>();
            for (String name : u13Names) {
                u13Teams.add(teamRepository.save(Team.builder().name(name).ageGroup(u13).build()));
            }

            // Aufteilung auf zwei Gruppen à 6 Teams
            League gruppeA_U13 = leagueRepository.save(League.builder()
                    .name("Gruppe A (U13)").tournament(sommerCup).ageGroup(u13).round(gruppenphase)
                    .teams(new ArrayList<>(u13Teams.subList(0, 12))).build());



            // 4. Ausführung der Spielplan-Generierung
            gamePlanGeneratorService.generateScheduleForLeague(gruppeA_U13, sommerCup);

            // 5. TEST DATEN ERSTELLEN: ZUFÄLLIGE ERGEBNISSE EINTRAGEN (WIRD ÜBER DEN TRANSAKTIONALEN SERVICE GEMACHT)
            System.out.println("\n--- Zufallsergebnisse werden eingetragen (Transaktion Phase) ---");
            dataCompletionService.completeGamesRandomly(gruppeA_U13);

            // Ergänze für U17:
            gamePlanGeneratorService.generateScheduleForLeague(gruppeA_U17, sommerCup);

            dataCompletionService.completeGamesRandomly(gruppeA_U17);
        };
    }
}