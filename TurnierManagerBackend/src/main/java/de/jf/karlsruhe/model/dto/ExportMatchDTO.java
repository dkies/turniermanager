package de.jf.karlsruhe.model.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ExportMatchDTO {
    private long id;
    private String startTime;
    private Object field;
    private String teamA;
    private String teamB;
    private String status;
    private Integer scoreA;
    private Integer scoreB;
}
