package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.base.AgeGroup;
import de.jf.karlsruhe.model.dto.AgeGroupCreationDTO; // NEU
import de.jf.karlsruhe.model.dto.AgeGroupBulkCreationDTO; // NEU
import de.jf.karlsruhe.service.AgeGroupService; // NEU

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import lombok.RequiredArgsConstructor; // Besser als @Autowired für Controller

import java.util.List;
import java.util.UUID;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/agegroups")
@RequiredArgsConstructor
public class AgeGroupController {

    private final AgeGroupService ageGroupService;

    @PostMapping("/create")
    public ResponseEntity<AgeGroup> createAgeGroup(@RequestBody AgeGroupCreationDTO dto) {
        AgeGroup savedAgeGroup = ageGroupService.createAgeGroup(dto);
        return ResponseEntity.ok(savedAgeGroup);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAgeGroup(@PathVariable UUID id) {
        boolean deleted = ageGroupService.deleteAgeGroup(id);

        if (deleted) {
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @PostMapping("/bulk")
    public ResponseEntity<List<AgeGroup>> createMultipleAgeGroups(@RequestBody AgeGroupBulkCreationDTO dto) {
        List<AgeGroup> savedAgeGroups = ageGroupService.createMultipleAgeGroups(dto);
        return ResponseEntity.ok(savedAgeGroups);
    }


    @GetMapping("/getAll")
    public ResponseEntity<List<AgeGroup>> getAllAgeGroups() {
        List<AgeGroup> ageGroups = ageGroupService.getAllAgeGroups();
        return ResponseEntity.ok(ageGroups);
    }
}