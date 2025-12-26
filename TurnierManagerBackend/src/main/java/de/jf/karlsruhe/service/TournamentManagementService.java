package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.Tournament;
import de.jf.karlsruhe.model.dto.TournamentCreationDTO;
import de.jf.karlsruhe.model.repos.TournamentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class TournamentManagementService {

    private final TournamentRepository tournamentRepository;

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
}