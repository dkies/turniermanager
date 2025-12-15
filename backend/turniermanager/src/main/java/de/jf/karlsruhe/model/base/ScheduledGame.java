package de.jf.karlsruhe.model.base;

import de.jf.karlsruhe.model.enums.GameStatus;
import jakarta.persistence.*;
import lombok.*;
import java.util.UUID;

@Entity
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScheduledGame {

    @Id
    @GeneratedValue(generator = "UUID")
    private UUID id; // Das ist die Game-ID

    private int gameNumber;

    // --- Spiel-spezifische Daten ---
    private int teamAScore;
    private int teamBScore;

    @ManyToOne
    @JoinColumn(name = "team_a_id")
    private Team teamA;

    @ManyToOne
    @JoinColumn(name = "team_b_id")
    private Team teamB;

    @Enumerated(EnumType.STRING) // Speichert den Enum-Namen als String in der DB
    @Builder.Default // Wird beim Bauen automatisch gesetzt, falls nicht explizit angegeben
    private GameStatus status = GameStatus.SCHEDULED;

    // --- Verknüpfung zum Planungs-Header ---
    @OneToOne // EINE Spiel-Instanz gehört zu EINEM Planungs-Eintrag
    @JoinColumn(name = "schedule_item_id")
    private ScheduleItem scheduleItem;
}
