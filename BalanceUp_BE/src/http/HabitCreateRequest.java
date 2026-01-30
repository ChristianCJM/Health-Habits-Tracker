package http;

import java.math.BigDecimal;

public class HabitCreateRequest {
    private String name;
    private String type;         // "numeric" or "boolean"
    private String unit;
    private BigDecimal dailyTarget;
    private String category;     // "water", "movement", "sleep", "food", "custom"

    // getters e setters obrigatórios para o Gson
    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    public BigDecimal getDailyTarget() {
        return dailyTarget;
    }

    public void setDailyTarget(BigDecimal dailyTarget) {
        this.dailyTarget = dailyTarget;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }
}
