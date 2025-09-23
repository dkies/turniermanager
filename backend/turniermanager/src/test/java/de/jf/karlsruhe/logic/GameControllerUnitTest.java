package de.jf.karlsruhe.logic;

import de.jf.karlsruhe.controller.GameController;
import de.jf.karlsruhe.model.base.Pitch;
import de.jf.karlsruhe.model.base.Team;
import de.jf.karlsruhe.model.repos.GameRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.ResponseEntity;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class GameControllerUnitTest {

    @Mock
    private GameRepository gameRepository;

    @InjectMocks
    private GameController gameController;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
    }

    @Test
    void testUpdateGameScores() {
        // Arrange: Spiel erstellen
        UUID gameId = UUID.randomUUID();
        Game game = Game.builder()
                .id(gameId)
                .teamAScore(0)
                .teamBScore(0)
                .build();

        when(gameRepository.findById(gameId)).thenReturn(Optional.of(game));
        when(gameRepository.save(any(Game.class))).thenAnswer(invocation -> invocation.getArgument(0));

        // Act: Ergebnisse aktualisieren
        ResponseEntity<Game> response = gameController.updateGameScores(gameId, 3, 2);

        // Assert: Überprüfen, dass das Spiel aktualisiert wurde
        assertNotNull(response.getBody());
        assertEquals(3, response.getBody().getTeamAScore());
        assertEquals(2, response.getBody().getTeamBScore());
        verify(gameRepository, times(1)).findById(gameId);
        verify(gameRepository, times(1)).save(game);
    }

    @Test
    void testUpdateGameScores_GameNotFound() {
        // Arrange: Kein Spiel vorhanden
        UUID gameId = UUID.randomUUID();
        when(gameRepository.findById(gameId)).thenReturn(Optional.empty());

        // Act & Assert: Erwartete Ausnahme
        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            gameController.updateGameScores(gameId, 3, 2);
        });

        assertEquals("Spiel mit ID " + gameId + " nicht gefunden", exception.getMessage());
        verify(gameRepository, times(1)).findById(gameId);
        verify(gameRepository, times(0)).save(any(Game.class));
    }

    @Test
    void testGetGameDetails() {
        // Arrange: Spiel mit Details erstellen
        UUID gameId = UUID.randomUUID();
        Team teamA = Team.builder().name("Team A").build();
        Team teamB = Team.builder().name("Team B").build();
        Pitch pitch = Pitch.builder().name("Hauptplatz").build();

        Game game = Game.builder()
                .id(gameId)
                .startTime(LocalDateTime.of(2023, 10, 25, 14, 0))
                .teamA(teamA)
                .teamB(teamB)
                .teamAScore(1)
                .teamBScore(2)
                .pitch(pitch)
                .build();

        when(gameRepository.findById(gameId)).thenReturn(Optional.of(game));

        // Act: Spieldetails abrufen
        ResponseEntity<String> response = gameController.getGameDetails(gameId);

        // Assert: Überprüfen, dass die Details korrekt sind
        assertNotNull(response.getBody());
        String expectedDetails = String.format(
                "Spiel-ID: %s\n" +
                "Spielbeginn: 2023-10-25T14:00\n" +
                "Team A: Team A [Punkte: 1]\n" +
                "Team B: Team B [Punkte: 2]\n" +
                "Spielfeld: Hauptplatz",
                gameId
        );
        assertEquals(expectedDetails, response.getBody());
        verify(gameRepository, times(1)).findById(gameId);
    }

    @Test
    void testGetGameDetails_GameNotFound() {
        // Arrange: Kein Spiel vorhanden
        UUID gameId = UUID.randomUUID();
        when(gameRepository.findById(gameId)).thenReturn(Optional.empty());

        // Act & Assert: Erwartete Ausnahme
        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class, () -> {
            gameController.getGameDetails(gameId);
        });

        assertEquals("Spiel mit ID " + gameId + " nicht gefunden", exception.getMessage());
        verify(gameRepository, times(1)).findById(gameId);
    }

    @Test
    void testGetGamesByPitch() {
        // Arrange: Spiele für ein Spielfeld
        UUID pitchId = UUID.randomUUID();
        Pitch pitch = Pitch.builder().id(pitchId).name("Nebenplatz").build();

        Game game1 = Game.builder().id(UUID.randomUUID()).pitch(pitch).build();
        Game game2 = Game.builder().id(UUID.randomUUID()).pitch(pitch).build();

        List<Game> games = Arrays.asList(game1, game2);
        when(gameRepository.findByPitchId(pitchId)).thenReturn(games);

        // Act: Spiele abrufen
        ResponseEntity<List<Game>> response = gameController.getGamesByPitch(pitchId);

        // Assert: Überprüfen, dass die richtigen Spiele zurückgegeben werden
        assertNotNull(response.getBody());
        assertEquals(2, response.getBody().size());
        assertEquals(game1.getId(), response.getBody().get(0).getId());
        assertEquals(game2.getId(), response.getBody().get(1).getId());
        verify(gameRepository, times(1)).findByPitchId(pitchId);
    }

    @Test
    void testGetGamesByPitch_NoGamesFound() {
        // Arrange: Kein Spiel vorhanden
        UUID pitchId = UUID.randomUUID();
        when(gameRepository.findByPitchId(pitchId)).thenReturn(List.of());

        // Act: Spiele abrufen
        ResponseEntity<List<Game>> response = gameController.getGamesByPitch(pitchId);

        // Assert: Kein Inhalt sollte zurückgegeben werden
        assertNull(response.getBody());
        assertEquals(204, response.getStatusCodeValue());
        verify(gameRepository, times(1)).findByPitchId(pitchId);
    }
}