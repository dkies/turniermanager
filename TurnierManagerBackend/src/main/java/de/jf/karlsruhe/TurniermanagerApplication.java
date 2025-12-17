package de.jf.karlsruhe;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;

@SpringBootApplication
@EntityScan(basePackages = "de.jf.karlsruhe.model.base")
public class TurniermanagerApplication {

	public static void main(String[] args) {
		SpringApplication.run(TurniermanagerApplication.class, args);
	}

}
