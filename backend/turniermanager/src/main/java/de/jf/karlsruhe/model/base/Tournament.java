package de.jf.karlsruhe.model.base;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.GenericGenerator;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Tournament {

    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(
            name = "UUID",
            strategy = "org.hibernate.id.UUIDGenerator"
    )
    private UUID id;

    /**
     * Name des gesamten Events (z.B. "Sommer Cup 2025")
     */
    private String name;

    /**
     * Datum, an dem das Turnier beginnt
     */
    private LocalDateTime startTime;

    /**
     * Datum, an dem das Turnier endet
     */
    private LocalDate endDate;

    private int breakTimeInSeconds;

    private int playTimeInSeconds;
    /**
     * Optionale Beschreibung des Veranstaltungsorts
     */
    private String venue;

    // --- Beziehungen (One-to-Many) ---

    /**
     * 1. Verknüpfung zu den Ligen/Gruppen (ONE Tournament has MANY Leagues)
     */
    // 'mappedBy' verweist auf das Feld 'tournament' in der League-Entität
    // Cascade.ALL stellt sicher, dass Ligen gelöscht werden, wenn das Turnier gelöscht wird
    @OneToMany(mappedBy = "tournament", cascade = CascadeType.ALL, orphanRemoval = true)
    @ToString.Exclude
    private List<League> leagues;

    /**
     * 2. Verknüpfung zu den Phasen (ONE Tournament has MANY Rounds)
     */
    @OneToMany(mappedBy = "tournament", cascade = CascadeType.ALL, orphanRemoval = true)
    @ToString.Exclude
    private List<Round> rounds;

}