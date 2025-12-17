package de.jf.karlsruhe.service;

import de.jf.karlsruhe.model.base.AgeGroup;
import de.jf.karlsruhe.model.base.Team;
import de.jf.karlsruhe.model.dto.TeamCreationDTO;
import de.jf.karlsruhe.model.dto.TeamBulkCreationDTO;
import de.jf.karlsruhe.model.dto.TeamsSmallDTO; // DTO für die Ausgabe
import de.jf.karlsruhe.model.repos.AgeGroupRepository;
import de.jf.karlsruhe.model.repos.TeamRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TeamService {

    private final TeamRepository teamRepository;
    private final AgeGroupRepository ageGroupRepository;

    @Transactional
    public Team createTeam(TeamCreationDTO dto) {

        AgeGroup ageGroup = ageGroupRepository.findById(dto.ageGroupId())
                .orElseThrow(() -> new IllegalArgumentException("Altersgruppe mit ID " + dto.ageGroupId() + " nicht gefunden."));

        Team team = Team.builder()
                .name(dto.name())
                .ageGroup(ageGroup)
                .build();

        return teamRepository.save(team);
    }

    @Transactional
    public List<Team> createMultipleTeams(TeamBulkCreationDTO dto) {

        List<Team> teams = dto.teams().stream()
                .map(teamDto -> {
                    AgeGroup ageGroup = ageGroupRepository.findById(teamDto.ageGroupId())
                            .orElseThrow(() -> new IllegalArgumentException("Altersgruppe mit ID " + teamDto.ageGroupId() + " nicht gefunden."));

                    return Team.builder()
                            .name(teamDto.name())
                            .ageGroup(ageGroup)
                            .build();
                })
                .collect(Collectors.toList());

        return teamRepository.saveAll(teams);
    }

    @Transactional
    public boolean deleteTeam(UUID id) {
        if (teamRepository.existsById(id)) {
            teamRepository.deleteById(id);
            return true;
        }
        return false;
    }

    @Transactional(readOnly = true)
    public List<TeamsSmallDTO> getTeamsSmall(String leagueName, String ageGroupName) {

        List<Team> teams = teamRepository.findAll();

        if (ageGroupName != null && !ageGroupName.isEmpty()) {
            teams = teamRepository.findAll().stream()
                    .filter(t -> t.getAgeGroup().getName().equalsIgnoreCase(ageGroupName))
                    .toList();
        } else {
            teams = teamRepository.findAll();
        }

        return teams.stream()
                .map(team -> new TeamsSmallDTO(team.getId(), team.getName(), team.getAgeGroup().getName()))
                .toList();
    }
}