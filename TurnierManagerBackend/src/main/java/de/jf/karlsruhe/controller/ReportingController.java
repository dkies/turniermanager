package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.dto.RoundStatsDTO;
import de.jf.karlsruhe.service.ReportingService;
import de.jf.karlsruhe.service.RoundStatsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/reporting")
@RequiredArgsConstructor
public class ReportingController {

    private final RoundStatsService roundStatsService;
    private final ReportingService reportingService;

    @GetMapping(value = "/tournament-results/{ageGroupId}", produces = MediaType.APPLICATION_PDF_VALUE)
    public ResponseEntity<byte[]> getTournamentResults(@RequestBody UUID ageGroupId) {
        RoundStatsDTO stats = roundStatsService.getStatsByAgeGroup(ageGroupId);

        // 2. PDF generieren
        byte[] pdfBytes = reportingService.generateTournamentResultsPdf(stats);

        if (pdfBytes == null || pdfBytes.length == 0) {
            return ResponseEntity.noContent().build();
        }

        HttpHeaders headers = new HttpHeaders();
        headers.add(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=ergebnisse_" + stats.roundName() + ".pdf");

        return ResponseEntity.ok()
                .headers(headers)
                .body(pdfBytes);
    }
}