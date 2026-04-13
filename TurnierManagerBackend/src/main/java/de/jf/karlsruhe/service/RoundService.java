package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.Round;
import de.jf.karlsruhe.model.base.Tournament;
import de.jf.karlsruhe.model.dto.RoundCreationDTO;
import de.jf.karlsruhe.model.repos.RoundRepository;
import de.jf.karlsruhe.model.repos.TournamentRepository; // Annahme: Existiert
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class RoundService {

    private final RoundRepository roundRepository;
    private final TournamentRepository tournamentRepository; // Annahme: Für die Validierung

    /**
     * Lädt die Tournament-Entität anhand der ID.
     */
    private Tournament getTournamentById(UUID id) {
        return tournamentRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Turnier mit ID " + id + " nicht gefunden."));
    }

    /**
     * Erstellt eine einzelne Runde.
     */
    @Transactional
    public Round createRound(RoundCreationDTO dto) {
        Tournament tournament = tournamentRepository.findAll().getFirst();

        Round round = Round.builder()
                .name(dto.name())
                .roundType(dto.roundType())
                .orderIndex(dto.orderIndex())
                .tournament(tournament)
                .build();

        return roundRepository.save(round);
    }

    /**
     * Liest eine Runde anhand der ID.
     */
    @Transactional(readOnly = true)
    public Optional<Round> getRoundById(UUID id) {
        return roundRepository.findById(id);
    }

    /**
     * Liest alle Runden.
     */
    @Transactional(readOnly = true)
    public List<Round> getAllRounds() {
        return roundRepository.findAll();
    }

    /**
     * Löscht eine Runde anhand der ID.
     * @return true, wenn gelöscht, false, wenn nicht gefunden.
     */
    @Transactional
    public boolean deleteRound(UUID id) {
        if (roundRepository.existsById(id)) {
            roundRepository.deleteById(id);
            return true;
        }
        return false;
    }
}