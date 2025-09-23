package de.jf.karlsruhe.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*")

@RestController
@RequestMapping("/turniersetup/pitches")
@RequiredArgsConstructor
public class PitchController {

//    private final PitchRepository pitchRepository;
//    private final GameRepository gameRepository;
//    private final RoundRepository roundRepository;
//
//    // Create a new Pitch
//    @PostMapping
//    public ResponseEntity<Pitch> createPitch(@RequestBody Pitch pitch) {
//        Pitch savedPitch = pitchRepository.save(pitch);
//        return ResponseEntity.ok(savedPitch);
//    }
//
//    // Read/Get a Pitch by ID
//    @GetMapping("/{id}")
//    public ResponseEntity<Pitch> getPitchById(@PathVariable UUID id) {
//        Optional<Pitch> optionalPitch = pitchRepository.findById(id);
//        return optionalPitch.map(ResponseEntity::ok)
//                .orElse(ResponseEntity.notFound().build());
//    }
//
//    // Read/Get all Pitches
//    @GetMapping
//    public ResponseEntity<List<Pitch>> getAllPitches() {
//        List<Pitch> pitches = pitchRepository.findAll();
//        return ResponseEntity.ok(pitches);
//    }
//
//    // Update a Pitch
//    @PutMapping("/{id}")
//    public ResponseEntity<Pitch> updatePitch(@PathVariable UUID id, @RequestBody Pitch pitchDetails) {
//        Optional<Pitch> optionalPitch = pitchRepository.findById(id);
//
//        if (optionalPitch.isPresent()) {
//            Pitch existingPitch = optionalPitch.get();
//            existingPitch.setName(pitchDetails.getName());
//            existingPitch.setAgeGroups(pitchDetails.getAgeGroups());
//            Pitch updatedPitch = pitchRepository.save(existingPitch);
//            return ResponseEntity.ok(updatedPitch);
//        } else {
//            return ResponseEntity.notFound().build();
//        }
//    }
//
//    // Delete a Pitch
//    @DeleteMapping("/{id}")
//    public ResponseEntity<Void> deletePitch(@PathVariable UUID id) {
//        if (pitchRepository.existsById(id)) {
//            pitchRepository.deleteById(id);
//            return ResponseEntity.noContent().build();
//        } else {
//            return ResponseEntity.notFound().build();
//        }
//    }
//
//    // Bulk Insert Multiple Pitches
//    @PostMapping("/bulk")
//    public ResponseEntity<List<Pitch>> createMultiplePitches(@RequestBody List<Pitch> pitches) {
//        List<Pitch> savedPitches = pitchRepository.saveAll(pitches);
//        return ResponseEntity.ok(savedPitches);
//    }
//
//    @GetMapping(value = "/result-card/{id}", produces = MediaType.APPLICATION_PDF_VALUE)
//    public ResponseEntity<byte[]> getResultCards(@PathVariable UUID id) {
//        List<GameDTO> games = new ArrayList<>();
//        Optional<Pitch> optionalPitch = pitchRepository.findById(id);
//
//        if (optionalPitch.isEmpty()) {
//            return ResponseEntity.notFound().build();
//        }
//
//        Pitch pitch = optionalPitch.get();
//        List<Game> byPitchId = getActiveRoundGamesByPitchId(pitch.getId());
//        byPitchId.sort(Comparator.comparing(Game::getGameNumber));
//        if(byPitchId.isEmpty())return ResponseEntity.noContent().build();
//        byPitchId.forEach(game -> {
//            games.add(new GameDTO(game.getTeamA().getName(), game.getTeamB().getName(), pitch.getName(), game.getGameNumber()));
//        });
//
//        try {
//            ByteArrayOutputStream out = createPdf(games);
//            HttpHeaders headers = new HttpHeaders();
//            headers.add(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=spielfeld" + id + ".pdf");
//            return ResponseEntity.ok().headers(headers).body(out.toByteArray());
//        } catch (RuntimeException e) {
//            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
//        }
//    }
//
//    private ByteArrayOutputStream createPdf(List<GameDTO> games) {
//        try {
//            ByteArrayOutputStream out = new ByteArrayOutputStream();
//            Document document = new Document(PageSize.A4.rotate());
//            PdfWriter writer = PdfWriter.getInstance(document, out);
//            writer.setCloseStream(false);
//            document.open();
//
//            Font headlineFont = new Font(
//                    BaseFont.createFont(BaseFont.HELVETICA_BOLD, BaseFont.CP1252, BaseFont.NOT_EMBEDDED),
//                    20F,
//                    Font.BOLD,
//                    Color.BLACK
//            );
//            Font boldFont = new Font(
//                    BaseFont.createFont(BaseFont.HELVETICA_BOLD, BaseFont.CP1252, BaseFont.NOT_EMBEDDED),
//                    14F,
//                    Font.BOLD,
//                    Color.BLACK
//            );
//
//            for (GameDTO game : games) {
//                Paragraph header = new Paragraph("Platz: " + game.fieldNumber + "    Spiel: " + game.matchNumber, headlineFont);
//                header.setAlignment(Element.ALIGN_CENTER);
//                document.add(header);
//                document.add(new Paragraph("\n"));
//
//                Table table = new Table(2);
//                table.setBorderWidth(1F);
//                table.setBorderColor(new Color(0, 0, 0));
//                table.setPadding(5F);
//                table.setWidth(100);
//                table.addCell(createCell(game.team1 + "\n\n\n\n\n\n\n"));
//                table.addCell(createCell(game.team2));
//                table.endHeaders();
//                table.addCell(createCell(game.team2 + "\n\n\n\n\n\n\n"));
//                table.addCell(createCell(game.team1));
//                document.add(table);
//                document.add(new Paragraph("\n"));
//
//                document.add(new Paragraph("Endergebnis:", headlineFont));
//                document.add(new Paragraph("\n" + game.team1 + ": ________________", boldFont));
//                document.add(new Paragraph("\n" + game.team2 + ": ________________", boldFont));
//
//                document.newPage();
//            }
//
//            document.close();
//            return out;
//        } catch (IOException e) {
//            throw new RuntimeException(e);
//        }
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
//    @Data
//    @AllArgsConstructor
//    @NoArgsConstructor
//    public class GameDTO {
//        String team1;
//        String team2;
//        String fieldNumber;
//        long matchNumber;
//    }
//
//    public List<Game> getActiveRoundGames() {
//        return roundRepository.findByActiveTrue().stream()
//                .flatMap(round -> gameRepository.findByRound(round).stream())
//                .collect(Collectors.toList());
//    }
//
//    public List<Game> getActiveRoundGamesByPitchId(UUID pitchId) {
//        return roundRepository.findByActiveTrue().stream()
//                .flatMap(round -> gameRepository.findByRound(round).stream())
//                .filter(game -> game.getPitch().getId().equals(pitchId))
//                .collect(Collectors.toList());
//    }


}