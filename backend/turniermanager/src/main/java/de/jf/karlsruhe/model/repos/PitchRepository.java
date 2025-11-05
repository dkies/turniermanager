package de.jf.karlsruhe.model.repos;

import de.jf.karlsruhe.model.base.AgeGroup;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import de.jf.karlsruhe.model.base.Pitch;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PitchRepository extends JpaRepository<Pitch, UUID>{
//    @EntityGraph(attributePaths = "ageGroups")
//    List<Pitch> findAll();
//
//    List<Pitch> findByAgeGroup(AgeGroup ageGroup);
}
