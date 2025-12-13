package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.base.ScheduledBreak;
import de.jf.karlsruhe.model.dto.BreakGlobalCreationDTO;
import de.jf.karlsruhe.model.dto.BreakSingleCreationDTO;
import de.jf.karlsruhe.service.BreakScheduleService;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@AllArgsConstructor
@RestController
@RequestMapping("/breaks")
public class BreakController {

    private final BreakScheduleService breakService;

    /**
     * Erstellt eine neue geplante Pause (Global oder Pitch-spezifisch).
     * POST /api/breaks
     */
    @PostMapping("/createBreak")
    public ResponseEntity<List<ScheduledBreak>> createBreak(@RequestBody BreakSingleCreationDTO dto) {
        List<ScheduledBreak> response = breakService.setBreakForAgeGroup(dto);

        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @PostMapping("/createGlobalBreak")
    public ResponseEntity<List<ScheduledBreak>> createBreak(@RequestBody BreakGlobalCreationDTO dto) {
        List<ScheduledBreak> response = breakService.setBreakForAllAgeGroups(dto);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }
}