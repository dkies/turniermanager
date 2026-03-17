package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.base.ScheduledBreak;
import de.jf.karlsruhe.model.dto.BreakGlobalCreationDTO;
import de.jf.karlsruhe.model.dto.BreakSingleCreationDTO;
import de.jf.karlsruhe.service.BreakScheduleService;
import de.jf.karlsruhe.service.BreakScheduleServiceOLD;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@CrossOrigin(origins = "*")
@AllArgsConstructor
@RestController
@RequestMapping("/breaks")
public class BreakController {

    private final BreakScheduleService breakService;


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

    @DeleteMapping("/delete")
    public ResponseEntity<Void> deleteBreak(@RequestBody UUID id) {
        breakService.deleteBreak(id);
        return ResponseEntity.ok().build();
    }

}