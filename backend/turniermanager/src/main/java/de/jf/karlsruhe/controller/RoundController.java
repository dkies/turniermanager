package de.jf.karlsruhe.controller;

import lombok.AllArgsConstructor;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*")

@RestController
@RequestMapping("/turniersetup/rounds")
@AllArgsConstructor
public class RoundController {
//
//    private final RoundRepository roundRepository;
//    private final GameRepository gameRepository;
//
//
//    @GetMapping
//    public ResponseEntity<List<RoundDTO>> getAllRounds() {
//        return ResponseEntity.ok(
//            roundRepository.findAll().stream()
//                .map(round -> new RoundDTO(round.getId(), round.getName(), round.getTournament().getId(), round.isActive()))
//                .toList()
//        );
//    }
//
//    @GetMapping(path = "/result-cards", produces = MediaType.APPLICATION_PDF_VALUE)
//    public ResponseEntity<byte[]> getResultCards(@RequestParam List<UUID> roundIds) {
//        List<Round> rounds = roundRepository.findByIds(roundIds);
//        if (rounds.isEmpty()) {
//            return ResponseEntity.notFound().build();
//        }
//
//        List<Game> games = gameRepository.findByRounds(rounds).stream()
//                .sorted(Comparator.comparing(Game::getGameNumber)).toList();
//
//        if (games.isEmpty()) {
//            return ResponseEntity.notFound().build();
//        }
//
//        Map<UUID,List<Game>> gamesPerPitch = new HashMap<>();
//        for (Game game : games) {
//            gamesPerPitch.computeIfAbsent(game.getPitch().getId(), k -> new ArrayList<>()).add(game);
//        }
//
//        List<UUID> pitchByLength = gamesPerPitch.keySet().stream()
//                .sorted(Comparator.comparingInt(o -> gamesPerPitch.get(o).size()).reversed())
//                .toList();
//
//
//        try {
//            ByteArrayOutputStream out = createPdf(gamesPerPitch, pitchByLength);
//            HttpHeaders headers = new HttpHeaders();
//            headers.add(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=result-card-rounds.pdf");
//            return ResponseEntity.ok().headers(headers).body(out.toByteArray());
//        } catch (RuntimeException e) {
//            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
//        }
//    }
//
//    private ByteArrayOutputStream createPdf(Map<UUID, List<Game>> games, List<UUID> pitchList) {
//        try {
//            ByteArrayOutputStream out = new ByteArrayOutputStream();
//            Document document = new Document(PageSize.A4);
//            PdfWriter writer = PdfWriter.getInstance(document, out);
//            writer.setCloseStream(false);
//            document.open();
//
//
//            for (int pitchCount = 0; pitchCount < pitchList.size(); pitchCount = pitchCount + 2) {
//                List<Game> topGames = games.get(pitchList.get(pitchCount));
//                List<Game> bottomGames = pitchCount + 1 < pitchList.size() ? games.get(pitchList.get(pitchCount + 1)) : List.of();
//
//                for (int gameNumber = 0; gameNumber < topGames.size(); gameNumber++) {
//                    Game topgame = topGames.get(gameNumber);
//                    addGame(topgame, document);
//                    Paragraph divider = new Paragraph("\n------------------------------------------------------------------------------------------------");
//                    divider.setSpacingAfter(30f);
//                    divider.setAlignment(Element.ALIGN_CENTER);
//                    document.add(divider);
//
//                    if (gameNumber < bottomGames.size()) {
//                        Game bottomgame = bottomGames.get(gameNumber);
//                        addGame(bottomgame, document);
//                    }
//                    document.newPage();
//
//                }
//            }
//
//            document.close();
//            return out;
//        } catch (IOException e) {
//            throw new RuntimeException(e);
//        }
//    }
//
//    private static void addGame(Game game, Document document) throws DocumentException, IOException {
//        Font headlineFont = new Font(
//                BaseFont.createFont(BaseFont.HELVETICA_BOLD, BaseFont.CP1252, BaseFont.NOT_EMBEDDED),
//                18F,
//                Font.BOLD,
//                Color.BLACK
//        );
//        Font boldFont = new Font(
//                BaseFont.createFont(BaseFont.HELVETICA_BOLD, BaseFont.CP1252, BaseFont.NOT_EMBEDDED),
//                14F,
//                Font.BOLD,
//                Color.BLACK
//        );
//
//        Paragraph header = new Paragraph("Platz: " + game.getPitch().getName() + "    Spiel: " + game.getGameNumber(), headlineFont);
//        header.setAlignment(Element.ALIGN_CENTER);
//        document.add(header);
//
//        Table table = new Table(2);
//        table.setBorderWidth(1F);
//        table.setBorderColor(new Color(0, 0, 0));
//        table.setPadding(5F);
//        table.setWidth(100);
//        table.addCell(createCell(game.getTeamA().getName() + "\n\n\n\n\n"));
//        table.addCell(createCell(game.getTeamB().getName()));
//        table.endHeaders();
//        table.addCell(createCell(game.getTeamB().getName() + "\n\n\n\n\n"));
//        table.addCell(createCell(game.getTeamA().getName()));
//        document.add(table);
//
//        document.add(new Paragraph("Endergebnis:", headlineFont));
//        document.add(new Paragraph(game.getTeamA().getName() + ": ________________,     " + game.getTeamB().getName() + ": ________________", boldFont));
//    }
//
//    private static Cell createCell(String text) throws IOException {
//        Font font = new Font(
//                BaseFont.createFont(BaseFont.HELVETICA_BOLD, BaseFont.CP1252, BaseFont.NOT_EMBEDDED),
//                13F,
//                Font.BOLD,
//                Color.BLACK
//        );
//        Paragraph paragraph = new Paragraph(text, font);
//        paragraph.setAlignment(Element.ALIGN_CENTER);
//        Cell cell = new Cell(paragraph);
//        cell.setHorizontalAlignment(HorizontalAlignment.CENTER);
//        return cell;
//    }
//
//
//    @Data
//    @AllArgsConstructor
//    public static class RoundDTO {
//        private UUID id;
//        private String name;
//        private UUID tournamentId;
//        private boolean active;
//    }
}
