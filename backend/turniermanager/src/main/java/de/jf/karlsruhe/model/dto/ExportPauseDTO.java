package de.jf.karlsruhe.model.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ExportPauseDTO {
    private long id;
    private String startTime;
    private String endTime;
    private Object field;
    private String description;
}
