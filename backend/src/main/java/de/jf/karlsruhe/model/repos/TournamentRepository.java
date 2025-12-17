package de.jf.karlsruhe.model.repos;

import de.jf.karlsruhe.model.base.Tournament;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface TournamentRepository extends JpaRepository<Tournament, UUID> {
}
