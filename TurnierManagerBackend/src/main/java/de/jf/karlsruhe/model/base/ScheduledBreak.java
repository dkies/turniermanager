package de.jf.karlsruhe.model.base;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

// package de.jf.karlsruhe.model.base;

@Entity
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScheduledBreak {

    @Id
    @GeneratedValue(generator = "UUID")
    private UUID id; // Das ist die Break-ID

    private String message;

    // --- Verknüpfung zum Planungs-Header ---
    @OneToOne // EINE Pausen-Instanz gehört zu EINEM Planungs-Eintrag
    @JoinColumn(name = "schedule_item_id")
    private ScheduleItem scheduleItem;
}
