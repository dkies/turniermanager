package de.jf.karlsruhe.model.base;

import de.jf.karlsruhe.model.enums.ScheduledItemType;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScheduleItem {

    @Id
    @GeneratedValue(generator = "UUID")
    private UUID id;

    private LocalDateTime startTime;
    private LocalDateTime endTime;

    // Planungsattribute
    @ManyToOne
    @JoinColumn(name = "age_group_id")
    private AgeGroup ageGroup;

    // Wenn ein Spiel/Pause an einen Platz gebunden ist.
    @ManyToOne
    @JoinColumn(name = "pitch_id")
    private Pitch scheduledPitch;

    @Enumerated(EnumType.STRING) // Speichert den Enum-Namen als String in der DB
    @Builder.Default
    private ScheduledItemType itemType = ScheduledItemType.GAME; // 'GAME' oder 'BREAK'
}