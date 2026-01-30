package http;

import model.Habit;

import java.math.BigDecimal;
import java.util.UUID;

public class HabitResponse {

    private UUID id;
    private String name;
    private String type;
    private String unit;
    private BigDecimal dailyTarget;
    private String category;

    public static HabitResponse fromModel(Habit h) {
        HabitResponse r = new HabitResponse();
        r.id = h.getId();
        r.name = h.getName();
        r.type = h.getType();
        r.unit = h.getUnit();
        r.dailyTarget = h.getDailyTarget();
        r.category = h.getCategory();
        return r;
    }

    // getters (úteis se quiser converter de volta)
    public UUID getId() { return id; }
    public String getName() { return name; }
    public String getType() { return type; }
    public String getUnit() { return unit; }
    public BigDecimal getDailyTarget() { return dailyTarget; }
    public String getCategory() { return category; }
}
