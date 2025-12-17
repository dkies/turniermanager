package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.AgeGroup;
import de.jf.karlsruhe.model.base.Pitch;
import de.jf.karlsruhe.model.dto.PitchCreationDTO;
import de.jf.karlsruhe.model.dto.PitchBulkCreationDTO;
import de.jf.karlsruhe.model.repos.AgeGroupRepository;
import de.jf.karlsruhe.model.repos.PitchRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PitchService {

    private final PitchRepository pitchRepository;
    private final AgeGroupRepository ageGroupRepository;

    private AgeGroup getAgeGroupById(UUID id) {
        return ageGroupRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Altersgruppe mit ID " + id + " nicht gefunden."));
    }

    @Transactional
    public Pitch createPitch(PitchCreationDTO dto) {
        AgeGroup ageGroup = getAgeGroupById(dto.allowedAgeGroupId());

        Pitch pitch = Pitch.builder()
                .name(dto.name())
                .ageGroup(ageGroup)
                .build();

        return pitchRepository.save(pitch);
    }

    @Transactional
    public List<Pitch> createMultiplePitches(PitchBulkCreationDTO dto) {
        List<Pitch> pitches = dto.pitches().stream()
                .map(pitchDto -> {
                    AgeGroup ageGroup = getAgeGroupById(pitchDto.allowedAgeGroupId());
                    return Pitch.builder()
                            .name(pitchDto.name())
                            .ageGroup(ageGroup)
                            .build();
                })
                .collect(Collectors.toList());

        return pitchRepository.saveAll(pitches);
    }

    @Transactional
    public Optional<Pitch> updatePitch(UUID id, PitchCreationDTO dto) {
        return pitchRepository.findById(id).map(existingPitch -> {
            AgeGroup ageGroup = getAgeGroupById(dto.allowedAgeGroupId());

            existingPitch.setName(dto.name());
            existingPitch.setAgeGroup(ageGroup);
            return pitchRepository.save(existingPitch);
        });
    }

    @Transactional(readOnly = true)
    public Optional<Pitch> getPitchById(UUID id) {
        return pitchRepository.findById(id);
    }

    @Transactional(readOnly = true)
    public List<Pitch> getAllPitches() {
        return pitchRepository.findAll();
    }

    @Transactional
    public boolean deletePitch(UUID id) {
        if (pitchRepository.existsById(id)) {
            pitchRepository.deleteById(id);
            return true;
        }
        return false;
    }
}