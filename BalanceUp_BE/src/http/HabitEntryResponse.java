package http;

import model.HabitEntry;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public class HabitEntryResponse {

    private UUID id;
    private UUID habitId;
    private LocalDate entryDate;
    private BigDecimal valueNumeric;
    private Boolean valueBool;

    public static HabitEntryResponse fromModel(HabitEntry e) {
        HabitEntryResponse r = new HabitEntryResponse();
        r.id = e.getId();
        r.habitId = e.getHabitId();
        r.entryDate = e.getEntryDate();
        r.valueNumeric = e.getValueNumeric();
        r.valueBool = e.getValueBool();
        return r;
    }

    public UUID getId() {
        return id;
    }

    public UUID getHabitId() {
        return habitId;
    }

    public LocalDate getEntryDate() {
        return entryDate;
    }

    public BigDecimal getValueNumeric() {
        return valueNumeric;
    }

    public Boolean getValueBool() {
        return valueBool;
    }
}
