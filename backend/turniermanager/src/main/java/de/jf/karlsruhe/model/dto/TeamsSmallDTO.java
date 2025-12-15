package de.jf.karlsruhe.model.dto;

import java.util.UUID;

public class TeamsSmallDTO {
    private UUID id;
    private String name;
    private String ageGroup;

    public TeamsSmallDTO() {
    }

    public TeamsSmallDTO(UUID id, String name, String ageGroup) {
        this.id = id;
        this.name = name;
        this.ageGroup = ageGroup;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getAgeGroup() {
        return ageGroup;
    }

    public void setAgeGroup(String ageGroup) {
        this.ageGroup = ageGroup;
    }
}
