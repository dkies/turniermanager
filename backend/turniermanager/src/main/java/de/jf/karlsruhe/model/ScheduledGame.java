package de.jf.karlsruhe.model;

import jakarta.persistence.Entity;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@Entity
@NoArgsConstructor
public class ScheduledGame extends ScheduledEntity {

    private int teamAScore;
    private int teamBScore;

    private long gameNumber;


}
