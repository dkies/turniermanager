package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.base.Pitch;
import de.jf.karlsruhe.model.dto.PitchCreationDTO;
import de.jf.karlsruhe.model.dto.PitchBulkCreationDTO;
import de.jf.karlsruhe.service.PitchService;
import de.jf.karlsruhe.service.ReportingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/pitches")
@RequiredArgsConstructor
public class PitchController {

    private final PitchService pitchService;
    private final ReportingService reportingService;

    // --- CRUD Operationen (PitchService) ---

    // Erstellt ein neues Spielfeld
    @PostMapping
    public ResponseEntity<Pitch> createPitch(@RequestBody PitchCreationDTO dto) {
        try {
            Pitch savedPitch = pitchService.createPitch(dto);
            return new ResponseEntity<>(savedPitch, HttpStatus.CREATED);
        } catch (IllegalArgumentException e) {
            // Fängt Fehler wie "Altersgruppe nicht gefunden"
            return ResponseEntity.badRequest().build();
        }
    }

    // Liest ein Spielfeld anhand der ID
    @GetMapping("/{id}")
    public ResponseEntity<Pitch> getPitchById(@PathVariable UUID id) {
        return pitchService.getPitchById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // Liest alle Spielfelder
    @GetMapping
    public ResponseEntity<List<Pitch>> getAllPitches() {
        List<Pitch> pitches = pitchService.getAllPitches();
        return ResponseEntity.ok(pitches);
    }

    // Aktualisiert ein Spielfeld
    @PutMapping("/{id}")
    public ResponseEntity<Pitch> updatePitch(@PathVariable UUID id, @RequestBody PitchCreationDTO dto) {
        try {
            return pitchService.updatePitch(id, dto)
                    .map(ResponseEntity::ok)
                    .orElse(ResponseEntity.notFound().build());
        } catch (IllegalArgumentException e) {
            // Fängt Fehler wie "Altersgruppe nicht gefunden"
            return ResponseEntity.badRequest().build();
        }
    }

    // Löscht ein Spielfeld
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePitch(@PathVariable UUID id) {
        boolean deleted = pitchService.deletePitch(id);

        if (deleted) {
            return ResponseEntity.noContent().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    // Massenerstellung von Spielfeldern
    @PostMapping("/bulk")
    public ResponseEntity<List<Pitch>> createMultiplePitches(@RequestBody PitchBulkCreationDTO dto) {
        try {
            List<Pitch> savedPitches = pitchService.createMultiplePitches(dto);
            return new ResponseEntity<>(savedPitches, HttpStatus.CREATED);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    // --- Reporting Operation (ReportingService) ---

    // Generiert die Ergebnis-Karten als PDF
    @GetMapping(value = "/result-card/{id}", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<byte[]> getResultCards(@PathVariable UUID id) {

        // Delegiert die gesamte Logik zur Datenerfassung und PDF-Generierung an den Service
        Optional<byte[]> pdfContent = reportingService.generateResultCardsPdf(id);

        if (pdfContent.isEmpty()) {
            // Spielfeld nicht gefunden
            return ResponseEntity.notFound().build();
        }

        byte[] pdfBytes = pdfContent.get();

        // Wenn das PDF leer ist (keine ausstehenden Spiele gefunden)
        if (pdfBytes.length == 0) {
            return ResponseEntity.noContent().build();
        }

        HttpHeaders headers = new HttpHeaders();
        // Setzt den Dateinamen für den Download
        headers.add(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=spielfeld" + id + ".pdf");

        return ResponseEntity.ok()
                .headers(headers)
                .body(pdfBytes);
    }
}