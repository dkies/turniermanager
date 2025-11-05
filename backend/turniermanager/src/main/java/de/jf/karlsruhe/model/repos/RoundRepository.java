package de.jf.karlsruhe.model.repos;

import de.jf.karlsruhe.model.base.AgeGroup;
import de.jf.karlsruhe.model.base.Round;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RoundRepository extends JpaRepository<Round, UUID> {
//    @Query("SELECT r FROM Round r JOIN FETCH r.leagues WHERE r.tournament.id = :tournamentId")
//    List<Round> findAllRoundsByTournamentId(UUID tournamentId);
//
//    @Query("SELECT r FROM Round r JOIN r.leagues l WHERE l.ageGroup = :ageGroup")
//    List<Round> findByAgeGroup(@Param("ageGroup") AgeGroup ageGroup);
//
//    List<Round> findByActiveTrue();
//
//    @Query("SELECT r FROM Round r JOIN r.leagues l WHERE l.ageGroup = :ageGroup AND r.active = true")
//    Optional<Round> findActiveRoundByAgeGroup(@Param("ageGroup") AgeGroup ageGroup);
//
//    @Query("SELECT r FROM Round r WHERE r.id IN :ids")
//    List<Round> findByIds(@Param("ids") List<UUID> ids);

}
