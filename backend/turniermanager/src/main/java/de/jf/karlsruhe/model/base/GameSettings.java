package de.jf.karlsruhe.model.base;

import jakarta.persistence.*;
import lombok.*;

import org.hibernate.annotations.GenericGenerator;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GameSettings {

	@Id
	@GeneratedValue(generator = "UUID")
	private UUID id = UUID.randomUUID();

	private LocalDateTime startTime;
	private int breakTime;
	private int playTime;
}