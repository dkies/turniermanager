package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.AgeGroup;
import de.jf.karlsruhe.model.dto.AgeGroupCreationDTO;
import de.jf.karlsruhe.model.dto.AgeGroupBulkCreationDTO;
import de.jf.karlsruhe.model.repos.AgeGroupRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AgeGroupService {

    private final AgeGroupRepository ageGroupRepository;


    @Transactional
    public AgeGroup createAgeGroup(AgeGroupCreationDTO dto) {
        AgeGroup ageGroup = AgeGroup.builder().name(dto.name()).build();
        return ageGroupRepository.save(ageGroup);
    }


    @Transactional
    public List<AgeGroup> createMultipleAgeGroups(AgeGroupBulkCreationDTO dto) {
        List<AgeGroup> ageGroups = dto.ageGroups().stream()
                .map(groupDto -> AgeGroup.builder().name(groupDto.name()).build())
                .collect(Collectors.toList());

        return ageGroupRepository.saveAll(ageGroups);
    }


    @Transactional
    public boolean deleteAgeGroup(UUID id) {
        if (ageGroupRepository.existsById(id)) {
            ageGroupRepository.deleteById(id);
            return true;
        }
        return false;
    }


    @Transactional(readOnly = true)
    public List<AgeGroup> getAllAgeGroups() {
        return ageGroupRepository.findAll();
    }
}