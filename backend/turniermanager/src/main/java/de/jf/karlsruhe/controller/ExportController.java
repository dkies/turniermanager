package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.dto.ExportAgeGroupDTO;
import de.jf.karlsruhe.model.dto.ExportTournamentDTO;
import de.jf.karlsruhe.service.ExportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/export")
@RequiredArgsConstructor
public class ExportController {

    private final ExportService exportService;

    @GetMapping("/tournament")
    public ResponseEntity<ExportTournamentDTO> exportTournament() {
        ExportTournamentDTO result = exportService.exportTournament();
        if (result == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(result);
    }

    @GetMapping("/agegroup/{slug}")
    public ResponseEntity<ExportAgeGroupDTO> exportAgeGroup(@PathVariable String slug) {
        ExportAgeGroupDTO result = exportService.exportAgeGroup(slug);
        if (result == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(result);
    }
}
