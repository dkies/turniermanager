package de.jf.karlsruhe.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http.csrf().disable()  // Deaktiviert CSRF-Schutz (nur für Tests geeignet)
            .authorizeHttpRequests()  // Hier verwenden wir authorizeHttpRequests() für die Konfiguration
                .requestMatchers("/**").permitAll()
                .anyRequest().authenticated()  // Erfordert Authentifizierung für alle anderen Endpunkte
            .and()
            .httpBasic();  // Optional: Basic Authentication, falls benötigt

        return http.build();
    }
}
