package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.Pitch;
import de.jf.karlsruhe.model.base.ScheduledGame;
import de.jf.karlsruhe.model.enums.GameStatus; // NEU
import de.jf.karlsruhe.model.repos.PitchRepository;
import de.jf.karlsruhe.model.repos.RoundRepository;
import de.jf.karlsruhe.model.repos.ScheduledGameRepository;
import de.jf.karlsruhe.model.repos.ScheduleItemRepository;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.ByteArrayOutputStream;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReportingService {

    private final PitchRepository pitchRepository;
    private final ScheduledGameRepository scheduledGameRepository;

    @Data
    @AllArgsConstructor
    public class GameReportDTO {
        String team1;
        String team2;
        String fieldNumber;
        int matchNumber;
    }

    @Transactional(readOnly = true)
    public Optional<byte[]> generateResultCardsPdf(UUID pitchId) {

        Pitch pitch = pitchRepository.findById(pitchId)
                .orElseThrow(() -> new IllegalArgumentException("Spielfeld mit ID " + pitchId + " nicht gefunden."));

        // NEU: Nur Spiele holen, die NICHT abgeschlossen sind
        List<ScheduledGame> games = getPendingGamesByPitch(pitch);

        if (games.isEmpty()) {
            return Optional.of(new byte[0]);
        }

        // ... (Mapping und Sortierung nach GameNumber) ...
        List<GameReportDTO> reportGames = games.stream()
                .sorted(Comparator.comparing(ScheduledGame::getGameNumber))
                .map(game -> new GameReportDTO(
                        game.getTeamA().getName(),
                        game.getTeamB().getName(),
                        pitch.getName(),
                        game.getGameNumber()))
                .collect(Collectors.toList());

        try {
            ByteArrayOutputStream out = createPdfContent(reportGames);
            return Optional.of(out.toByteArray());
        } catch (RuntimeException e) {
            throw new RuntimeException("Fehler beim Erstellen der PDF-Ergebniskarten.", e);
        }
    }

    private List<ScheduledGame> getPendingGamesByPitch(Pitch pitch) {

        return scheduledGameRepository.findByScheduleItem_ScheduledPitchAndStatusIsNotOrderByScheduleItem_StartTimeAsc(
                pitch,
                GameStatus.COMPLETED
        );
    }

    // ... (createPdfContent bleibt unverändert) ...
    private ByteArrayOutputStream createPdfContent(List<GameReportDTO> games) {
        // Implementierung der iText/PDF-Logik aus dem alten Controller kommt hierhin
        throw new UnsupportedOperationException("PDF-Generierungslogik muss implementiert werden.");
    }
}