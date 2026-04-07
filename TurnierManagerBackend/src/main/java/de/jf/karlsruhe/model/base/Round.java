package de.jf.karlsruhe.model.base;

import de.jf.karlsruhe.model.enums.RoundType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.GenericGenerator;

import java.util.List;
import java.util.UUID;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Round {

    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(
            name = "UUID",
            strategy = "org.hibernate.id.UUIDGenerator"
    )
    private UUID id;

    /**
     * Name der Phase (z.B. "Gruppenphase", "Viertelfinale", "Finale")
     */
    private String name;

    @Enumerated(EnumType.STRING)
    private RoundType roundType;

    /**
     * Die Reihenfolge der Runde im Turnier (z.B. 1 für Gruppenphase, 4 für Halbfinale)
     */
    private int orderIndex;

    // --- Beziehungen ---

    /**
     * 1. Verknüpfung zum Turnier (One Round belongs to ONE Tournament)
     */
    @ManyToOne
    @JoinColumn(name = "tournament_id", nullable = false)
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private Tournament tournament;

    /**
     * 2. Verknüpfung zu den Ligen (ONE Round has MANY Leagues/Groups)
     */
    // Dies ist die Gegenseite der Many-to-One in League
    @OneToMany(mappedBy = "round", cascade = CascadeType.ALL)
    @ToString.Exclude
    private List<League> leagues;
}