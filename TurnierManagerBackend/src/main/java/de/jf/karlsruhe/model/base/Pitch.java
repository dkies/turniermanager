package de.jf.karlsruhe.model.base;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.GenericGenerator;

import java.util.List;
import java.util.UUID;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Pitch {

	@Id
	@GeneratedValue(generator = "UUID")
	private UUID id;

	private String name;

	@ManyToOne
	@JoinColumn(name = "age_group_id")
	private AgeGroup ageGroup;
}