package de.jf.karlsruhe.service;


import com.lowagie.text.*;
import com.lowagie.text.Font;
import com.lowagie.text.pdf.BaseFont;
import com.lowagie.text.pdf.PdfWriter;
import com.lowagie.text.alignment.HorizontalAlignment;
import de.jf.karlsruhe.model.base.Pitch;
import de.jf.karlsruhe.model.base.ScheduledGame;
import de.jf.karlsruhe.model.dto.LeagueTableDTO;
import de.jf.karlsruhe.model.dto.RoundStatsDTO;
import de.jf.karlsruhe.model.dto.TeamScoreStatsDTO;
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
            games = scheduledGameRepository.findByPitchOrderByStartTime(pitch);
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

        return scheduledGameRepository.findByPitchAndItemStatusNot(
                pitch,
                GameStatus.COMPLETED_AND_STATED
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

    public byte[] generateTournamentResultsPdf(RoundStatsDTO stats) {
        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Document document = new Document(PageSize.A4);
            PdfWriter.getInstance(document, out);
            document.open();

            // Schriftarten definieren
            Font titleFont = new Font(Font.HELVETICA, 18, Font.BOLD, Color.BLACK);
            Font leagueFont = new Font(Font.HELVETICA, 14, Font.BOLD, Color.BLUE);
            Font headerFont = new Font(Font.HELVETICA, 10, Font.BOLD, Color.WHITE);
            Font cellFont = new Font(Font.HELVETICA, 10, Font.NORMAL, Color.BLACK);

            // Titel
            Paragraph title = new Paragraph("Abschlusstabelle: " + stats.roundName(), titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            title.setSpacingAfter(20);
            document.add(title);

            for (LeagueTableDTO leagueTable : stats.leagueTables()) {
                // Name der Liga / Gruppe
                Paragraph leagueName = new Paragraph("Liga: " + leagueTable.leagueName(), leagueFont);
                leagueName.setSpacingBefore(10);
                leagueName.setSpacingAfter(10);
                document.add(leagueName);

                // Tabelle erstellen (Platz, Team, Pkt, Diff, Tore)
                Table table = new Table(5);
                table.setWidth(100);
                table.setPadding(3);

                // Header setzen
                String[] headers = {"Platz", "Team", "Punkte", "Diff", "Tore"};
                for (String h : headers) {
                    Cell headerCell = new Cell(new Phrase(h, headerFont));
                    headerCell.setBackgroundColor(Color.DARK_GRAY);
                    headerCell.setHorizontalAlignment(HorizontalAlignment.CENTER);
                    table.addCell(headerCell);
                }

                int rank = 1;
                for (TeamScoreStatsDTO team : leagueTable.teams()) {
                    // Platzierung fett markieren für den Sieger
                    Font currentFont = (rank == 1) ? new Font(Font.HELVETICA, 10, Font.BOLD, Color.BLACK) : cellFont;

                    table.addCell(new Cell(new Phrase(String.valueOf(rank++), currentFont)));
                    table.addCell(new Cell(new Phrase(team.teamName(), currentFont)));
                    table.addCell(new Cell(new Phrase(String.valueOf(team.totalPoints()), currentFont)));
                    table.addCell(new Cell(new Phrase(String.valueOf(team.goalPointsDifference()), currentFont)));
                    table.addCell(new Cell(new Phrase(team.ownScoredGoals() + ":" + team.enemyScoredGoals(), currentFont)));
                }

                document.add(table);
                document.add(new Paragraph("\n")); // Abstand zur nächsten Liga
            }

            document.close();
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Fehler bei der PDF-Erstellung der Ergebnisse", e);
        }
    }

}