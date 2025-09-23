package de.jf.karlsruhe.model.base;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.GenericGenerator;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class League {

    @Id
    @GeneratedValue(generator = "UUID")
    private UUID id = UUID.randomUUID();

    private String name;

    boolean isQualification;


    @ManyToOne
    @JoinColumn(name = "tournament_id", nullable = false)
    @ToString.Exclude // Verhindert rekursive Schleifen in toString()
    @EqualsAndHashCode.Exclude
    private Tournament tournament; // Zugehöriges Turnier

    @ManyToMany
    @JoinTable(
            name = "league_team", // Name der Join-Tabelle
            joinColumns = @JoinColumn(name = "league_id"),  // Fremdschlüssel in der Join-Tabelle
            inverseJoinColumns = @JoinColumn(name = "team_id") // Fremdschlüssel für die Teams
    )
    @ToString.Exclude
    private List<Team> teams;

    @ManyToOne
    @JoinColumn(name = "age_group_id") // Fremdschlüssel in der League-Tabelle
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private AgeGroup ageGroup; // Altersgruppe der Liga (optional)

    @ManyToOne
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private Round round;

    public void addTeam(Team team) {
        if (this.teams == null) {
            this.teams = new ArrayList<>();
        }else{
            this.teams.add(team);
        }
    }
}