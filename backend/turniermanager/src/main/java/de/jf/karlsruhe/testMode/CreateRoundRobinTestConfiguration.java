package de.jf.karlsruhe.testMode;

import de.jf.karlsruhe.model.base.Team;
import de.jf.karlsruhe.util.RoundRobinScheduler;
import de.jf.karlsruhe.util.RoundRobinScheduler.GamePair;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicLong;
import java.util.stream.Collectors;

//@Configuration
public class CreateRoundRobinTestConfiguration {

    private static final AtomicLong teamCounter = new AtomicLong(1);

    private Team createTeam(String name) {
        return Team.builder()
                .id(UUID.randomUUID())
                .name(name + " " + teamCounter.getAndIncrement())
                .build();
    }

    @Bean
    public CommandLineRunner testRoundRobinScheduler() {
        return args -> {
            System.out.println("\n=========================================");
            System.out.println("--- Starte Test des RoundRobinScheduler ---");
            System.out.println("=========================================");

            // 1. Testfall: Gerade Anzahl (4 Teams)
            teamCounter.set(1);
            testScheduler(
                    "Testfall 1: 4 Teams (Gerade)",
                    Arrays.asList(
                            createTeam("Team A"),
                            createTeam("Team B"),
                            createTeam("Team C"),
                            createTeam("Team D")
                    )
            );

            // 2. Testfall: Ungerade Anzahl (5 Teams)
            teamCounter.set(1);
            testScheduler(
                    "Testfall 2: 5 Teams (Ungerade - mit Spielfrei-Runden)",
                    Arrays.asList(
                            createTeam("Team X"),
                            createTeam("Team Y"),
                            createTeam("Team Z"),
                            createTeam("Team W"),
                            createTeam("Team V")
                    )
            );

            // 3. Testfall: Minimale Anzahl (2 Teams)
            teamCounter.set(1);
            testScheduler(
                    "Testfall 3: 2 Teams (Minimum)",
                    Arrays.asList(
                            createTeam("Team 1"),
                            createTeam("Team 2")
                    )
            );

            System.out.println("\n--- RoundRobinScheduler Tests abgeschlossen. ---\n");
        };
    }

    private void testScheduler(String title, List<Team> teams) {
        System.out.println("\n-----------------------------------------");
        System.out.println(title);
        System.out.println("Teams: " + teams.stream().map(Team::getName).collect(Collectors.joining(", ")));

        // Formel für erwartete Spiele in einer einfachen Runde: N * (N - 1) / 2
        int expectedGames = teams.size() * (teams.size() - 1) / 2;
        System.out.println("Erwartete Spiele insgesamt: " + expectedGames);
        System.out.println("-----------------------------------------");

        // Aufruf der zu testenden Methode
        List<GamePair> fixtures = RoundRobinScheduler.generateSortedFixtures(teams);

        if (fixtures.isEmpty()) {
            System.out.println("Ergebnis: Keine Spiele generiert, korrekt für < 2 Teams.");
            return;
        }

        System.out.println("Generierte Spiele (" + fixtures.size() + "), sortiert nach Runde:");

        int gameCount = 1;
        for (GamePair pair : fixtures) {
            System.out.printf("  %02d. %s vs %s%n",
                    gameCount++,
                    pair.teamA().getName(),
                    pair.teamB().getName()
            );
        }

        // Endprüfung
        if (fixtures.size() == expectedGames) {
            System.out.println("✅ Anzahl der Spiele ist KORREKT.");
        } else {
            System.err.println("❌ ACHTUNG: Die Anzahl der Spiele weicht von der Erwartung ab!");
        }
    }
}