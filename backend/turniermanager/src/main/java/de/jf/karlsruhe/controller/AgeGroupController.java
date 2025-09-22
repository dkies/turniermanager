package de.jf.karlsruhe.controller;

import de.jf.karlsruhe.model.base.AgeGroup;
import de.jf.karlsruhe.model.repos.AgeGroupRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@CrossOrigin(origins = "*")

@RestController
@RequestMapping("/turniersetup/agegroups")
public class AgeGroupController {

//    @Autowired
//    private AgeGroupRepository ageGroupRepository;
//
//    @PostMapping("/create")
//    public ResponseEntity<AgeGroup> createAgeGroup(@RequestBody AgeGroup ageGroup) {
//        AgeGroup savedAgeGroup = ageGroupRepository.save(ageGroup);
//        return ResponseEntity.ok(savedAgeGroup);
//    }
//
//    @DeleteMapping("/{id}")
//    public ResponseEntity<Void> deleteAgeGroup(@PathVariable UUID id) {
//        if (ageGroupRepository.existsById(id)) {
//            ageGroupRepository.deleteById(id);
//            return ResponseEntity.ok().build();
//        } else {
//            return ResponseEntity.notFound().build();
//        }
//    }
//
//    @PostMapping("/bulk")
//    public ResponseEntity<Iterable<AgeGroup>> createMultipleAgeGroups(@RequestBody List<AgeGroup> ageGroups) {
//        List<AgeGroup> savedAgeGroups = ageGroupRepository.saveAll(ageGroups);
//        return ResponseEntity.ok(savedAgeGroups);
//    }
//
//
//    @GetMapping("/getAll")
//    public ResponseEntity<List<AgeGroup>> getAllAgeGroups() {
//        return ResponseEntity.ok(ageGroupRepository.findAll());
//    }
}
