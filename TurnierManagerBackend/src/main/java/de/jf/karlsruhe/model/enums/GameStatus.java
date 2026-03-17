package de.jf.karlsruhe.model.enums;

public enum GameStatus {
    /** Das Spiel ist geplant, aber noch nicht gestartet. */
    SCHEDULED,
    /** Das Spiel läuft gerade. */
    IN_PROGRESS,
    /** Das Spiel ist beendet und das Ergebnis ist eingetragen. */
    COMPLETED,
    /** Das Spiel wurde abgesagt oder verschoben. */
    CANCELED,
    /** Das Spiel wurde beendet und mit den Spielstatistiken versehen **/
    COMPLETED_AND_STATED
}
