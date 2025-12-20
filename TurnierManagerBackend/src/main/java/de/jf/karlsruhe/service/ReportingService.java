package de.jf.karlsruhe.service;


import com.lowagie.text.*;
import com.lowagie.text.Font;
import com.lowagie.text.pdf.BaseFont;
import com.lowagie.text.pdf.PdfWriter;
import com.lowagie.text.alignment.HorizontalAlignment;
import de.jf.karlsruhe.model.base.Pitch;
import de.jf.karlsruhe.model.base.ScheduledGame;
import de.jf.karlsruhe.model.enums.GameStatus;
import de.jf.karlsruhe.model.repos.PitchRepository;
import de.jf.karlsruhe.model.repos.ScheduledGameRepository;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.awt.*;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.*;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReportingService {

    private final PitchRepository pitchRepository;
    private final ScheduledGameRepository scheduledGameRepository;

    @Data
    @AllArgsConstructor
    public static class GameReportDTO {
        String team1;
        String team2;
        String fieldNumber;
        int matchNumber;
    }

    @Transactional(readOnly = true)
    public Optional<byte[]> generateResultCardsPdf(UUID pitchId, boolean printAll) {

        Pitch pitch = pitchRepository.findById(pitchId)
                .orElseThrow(() -> new IllegalArgumentException("Spielfeld mit ID " + pitchId + " nicht gefunden."));

        List<ScheduledGame> games = new ArrayList<>();
        if (printAll) {
            games = scheduledGameRepository.findByScheduleItem_ScheduledPitchOrderByScheduleItem_StartTimeAsc(pitch);
        } else {
            games = getPendingGamesByPitch(pitch);

        }

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
            ByteArrayOutputStream out = createPdf(reportGames);
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

    private ByteArrayOutputStream createPdf(List<GameReportDTO> games) {
        try {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            Document document = new Document(PageSize.A4.rotate());
            PdfWriter writer = PdfWriter.getInstance(document, out);
            writer.setCloseStream(false);
            document.open();

            Font headlineFont = new Font(
                    BaseFont.createFont(BaseFont.HELVETICA_BOLD, BaseFont.CP1252, BaseFont.NOT_EMBEDDED),
                    20F,
                    Font.BOLD,
                    Color.BLACK
            );
            Font boldFont = new Font(
                    BaseFont.createFont(BaseFont.HELVETICA_BOLD, BaseFont.CP1252, BaseFont.NOT_EMBEDDED),
                    14F,
                    Font.BOLD,
                    Color.BLACK
            );

            for (GameReportDTO game : games) {
                Paragraph header = new Paragraph("Platz: " + game.fieldNumber + "    Spiel: " + game.matchNumber, headlineFont);
                header.setAlignment(Element.ALIGN_CENTER);
                document.add(header);
                document.add(new Paragraph("\n"));

                Table table = new Table(2);
                table.setBorderWidth(1F);
                table.setBorderColor(new Color(0, 0, 0));
                table.setPadding(5F);
                table.setWidth(100);
                table.addCell(createCell(game.team1 + "\n\n\n\n\n\n\n"));
                table.addCell(createCell(game.team2));
                table.endHeaders();
                table.addCell(createCell(game.team2 + "\n\n\n\n\n\n\n"));
                table.addCell(createCell(game.team1));
                document.add(table);
                document.add(new Paragraph("\n"));

                document.add(new Paragraph("Endergebnis:", headlineFont));
                document.add(new Paragraph("\n" + game.team1 + ": ________________", boldFont));
                document.add(new Paragraph("\n" + game.team2 + ": ________________", boldFont));

                document.newPage();
            }

            document.close();
            return out;
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private static Cell createCell(String text) throws IOException {
        Font font = new Font(
                BaseFont.createFont(BaseFont.HELVETICA_BOLD, BaseFont.CP1252, BaseFont.NOT_EMBEDDED),
                13F,
                Font.BOLD,
                Color.BLACK
        );
        Paragraph paragraph = new Paragraph(text, font);
        paragraph.setAlignment(Element.ALIGN_CENTER);
        Cell cell = new Cell(paragraph);
        cell.setHorizontalAlignment(HorizontalAlignment.CENTER);
        return cell;
    }

}