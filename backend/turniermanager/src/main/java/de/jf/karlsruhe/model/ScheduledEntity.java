package de.jf.karlsruhe.model;

import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.MappedSuperclass;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@MappedSuperclass
public abstract class ScheduledEntity {

    @Id
    @GeneratedValue(generator = "UUID")
    private UUID id = UUID.randomUUID();

    private LocalDateTime startTime;

    private LocalDateTime actualStartTime;

    private LocalDateTime actualEndTime;

}
