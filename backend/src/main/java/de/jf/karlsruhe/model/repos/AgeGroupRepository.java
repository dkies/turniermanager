package de.jf.karlsruhe.model.repos;

import org.springframework.data.jpa.repository.JpaRepository;

import de.jf.karlsruhe.model.base.AgeGroup;

import java.util.List;
import java.util.UUID;

public interface AgeGroupRepository extends JpaRepository<AgeGroup, UUID> {
    List<AgeGroup> findByName(String name);
}
