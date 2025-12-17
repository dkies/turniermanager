package de.jf.karlsruhe.util;

import de.jf.karlsruhe.model.base.Team;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

public class RoundRobinScheduler {

    /** Speichert eine Spielpaarung. Team A ist Heim, Team B ist Auswärts. */
    public record GamePair(Team teamA, Team teamB) {}

    /**
     * Generiert den kompletten Round-Robin-Spielplan als flache, chronologisch sortierte Liste.
     * @param teams Die Liste der Teams in der Liga.
     * @return Eine einzelne, nach Runden sortierte Liste von GamePairs.
     */
    public static List<GamePair> generateSortedFixtures(List<Team> teams) {

        // 1. Interne Logik erstellt die notwendige Rundenstruktur (die "doppelte Liste")
        List<List<GamePair>> rounds = generateRounds(teams);

        // 2. Die Runden zu einer einzigen, flachen Liste zusammenfassen (flatMap)
        return rounds.stream()
                .flatMap(List::stream)
                .collect(Collectors.toList());
    }

    /**
     * Interne Methode: Generiert die Paarungen rundenweise mithilfe der Circle Method.
     */
    private static List<List<GamePair>> generateRounds(List<Team> teams) {
        if (teams == null || teams.size() < 2) {
            return Collections.emptyList();
        }

        List<Team> teamList = new ArrayList<>(teams);

        // Füge einen Dummy-Gegner (null) hinzu, wenn die Teamanzahl ungerade ist (für spielfreie Runden)
        boolean hasBye = (teamList.size() % 2 != 0);
        if (hasBye) {
            teamList.add(null);
        }

        int numTeams = teamList.size(); // Jetzt immer gerade
        int numRounds = numTeams - 1;
        List<List<GamePair>> allRounds = new ArrayList<>();

        // Starte Round-Robin-Algorithmus (Team an Index 0 bleibt fix)
        Team fixedTeam = teamList.get(0);

        for (int round = 0; round < numRounds; round++) {
            List<GamePair> currentRoundFixtures = new ArrayList<>();
            // Die rotierenden Teams (Index 1 bis Ende)
            List<Team> rotatingTeams = teamList.subList(1, numTeams);

            for (int i = 0; i < numTeams / 2; i++) {
                Team teamA, teamB;

                if (i == 0) {
                    // Das erste Spiel: Das FixedTeam (Index 0) spielt gegen das letzte rotierende Team
                    teamA = fixedTeam;
                    teamB = rotatingTeams.get(numTeams - 2);
                } else {
                    // Die restlichen Spiele: Innen- und Außenseiten der rotierenden Teams
                    teamA = rotatingTeams.get(i - 1);
                    teamB = rotatingTeams.get(numTeams - 2 - i);
                }

                // Füge die Paarung hinzu, wenn kein Team der Dummy-Gegner (null) ist
                if (teamA != null && teamB != null) {
                    // Optional: Wechsel des Heimrechts (hier: Runde 1, 3, 5 Heimrecht für TeamA)
                    if (round % 2 == 0) {
                        currentRoundFixtures.add(new GamePair(teamA, teamB));
                    } else {
                        currentRoundFixtures.add(new GamePair(teamB, teamA));
                    }
                }
            }
            allRounds.add(currentRoundFixtures);

            // Rotation der Teams (Circle Method)
            if (numTeams > 2) {
                // Das letzte rotierende Team (Ende der Liste)
                Team lastRotatingTeam = rotatingTeams.remove(rotatingTeams.size() - 1);
                // Kommt an den Anfang der rotierenden Liste
                rotatingTeams.add(0, lastRotatingTeam);
            }

            // Die Hauptliste für die nächste Runde aktualisieren (FixedTeam + rotierende Teams)
            teamList = new ArrayList<>();
            teamList.add(fixedTeam);
            teamList.addAll(rotatingTeams);
        }

        return allRounds;
    }
}