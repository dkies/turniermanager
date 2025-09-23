package de.jf.karlsruhe.model.base;

import jakarta.persistence.Entity;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.JoinColumn;

@Getter
@Setter
@AllArgsConstructor
@Entity
@NoArgsConstructor
public class ScheduledGame extends ScheduledEntity {

    private int teamAScore;
    private int teamBScore;

    private long gameNumber;

    @ManyToOne
    @JoinColumn(name = "pitch_id")
    private Pitch scheduledPitch;

}
