package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.Round;
import de.jf.karlsruhe.model.base.Tournament;
import de.jf.karlsruhe.model.dto.TournamentCreationDTO;
import de.jf.karlsruhe.model.repos.RoundRepository;
import de.jf.karlsruhe.model.repos.TournamentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;

@Service
@RequiredArgsConstructor
public class TournamentManagementService {

    private final TournamentRepository tournamentRepository;
    private final RoundRepository roundRepository;

    /**
     * Erstellt eine Tournament-Entität aus dem DTO und speichert diese in der Datenbank.
     *
     * @param dto Das TournamentCreationDTO vom Controller.
     */
    @Transactional
    public void createTournament(TournamentCreationDTO dto) {
        long amount = tournamentRepository.count();

        if(amount != 0) {
            return;
        }

        Tournament newTournament = Tournament.builder()
                .name(dto.name())
                .startTime(dto.startTime())
                .breakTimeInSeconds(dto.breakTimeInSeconds())
                .playTimeInSeconds(dto.playTimeInSeconds())
                .build();
        tournamentRepository.save(newTournament);
    }

    @Transactional
    public void updateTimeSettings(int playTimeInSeconds, int breakTimeInSeconds) {
        Tournament tournament = tournamentRepository.findAll().getFirst();
        tournament.setPlayTimeInSeconds(playTimeInSeconds);
        tournament.setBreakTimeInSeconds(breakTimeInSeconds);
        tournamentRepository.save(tournament);
    }

        public Round getActiveRound() {
            return roundRepository.findAll().stream()
                    // Vergleicht alle Runden anhand ihres orderIndex
                    .max(Comparator.comparingInt(Round::getOrderIndex))
                    // Wirft eine Exception, falls noch gar keine Runden generiert wurden
                    .orElseThrow(() -> new RuntimeException("Keine aktive Runde im System gefunden."));
    }
}