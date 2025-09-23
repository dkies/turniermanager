package de.jf.karlsruhe.model.base;

import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.MappedSuperclass;
import lombok.Getter;
import lombok.Setter;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.JoinColumn;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@MappedSuperclass
public abstract class ScheduledEntity {

    @ManyToOne
    @JoinColumn(name = "age_group_id")
    private AgeGroup ageGroup;

    @Id
    @GeneratedValue(generator = "UUID")
    private UUID id = UUID.randomUUID();

    private LocalDateTime startTime;

    private LocalDateTime actualStartTime;

    private LocalDateTime endTime;
}
