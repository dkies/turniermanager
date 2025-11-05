package de.jf.karlsruhe.model.base;

import jakarta.persistence.*;
import lombok.*;
import lombok.experimental.FieldDefaults;
import lombok.experimental.SuperBuilder;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Builder
@NoArgsConstructor // JPA-konform
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

    // NEU: Verknüpfung zu Pitch (optional, da Pausen global sein können)
    // Wenn ein Spiel/Pause an einen Platz gebunden ist.
    @ManyToOne
    @JoinColumn(name = "pitch_id")
    private Pitch scheduledPitch;

    // Der wichtigste Teil: Foreign Key zu Spiel oder Pause (siehe unten)
    private String itemType; // 'GAME' oder 'BREAK'
}
