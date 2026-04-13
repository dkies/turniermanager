package de.jf.karlsruhe.model.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ExportAgeGroupRefDTO {
    private String id;
    private String label;
    private String file;
}
