package dao;

import config.DatabaseConfig;
import model.Habit;

import java.math.BigDecimal;
import java.sql.*;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class HabitDAO {

    public List<Habit> findByUserId(UUID userId) throws SQLException {
        String sql = "SELECT id, user_id, name, type, unit, daily_target, category, created_at " +
                "FROM habits WHERE user_id = ?";
        List<Habit> result = new ArrayList<>();

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Habit h = mapRow(rs);
                    result.add(h);
                }
            }
        }
        return result;
    }

    public Habit insert(Habit habit) throws SQLException {
        String sql = "INSERT INTO habits (id, user_id, name, type, unit, daily_target, category, created_at) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

        if (habit.getId() == null) {
            habit.setId(UUID.randomUUID());
        }
        if (habit.getCreatedAt() == null) {
            habit.setCreatedAt(OffsetDateTime.now(ZoneOffset.UTC));
        }

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, habit.getId());
            ps.setObject(2, habit.getUserId());
            ps.setString(3, habit.getName());
            ps.setString(4, habit.getType());
            ps.setString(5, habit.getUnit());
            ps.setBigDecimal(6, habit.getDailyTarget());
            ps.setString(7, habit.getCategory());
            ps.setObject(8, habit.getCreatedAt());

            ps.executeUpdate();
        }

        return habit;
    }

    private Habit mapRow(ResultSet rs) throws SQLException {
        Habit h = new Habit();
        h.setId((UUID) rs.getObject("id"));
        h.setUserId((UUID) rs.getObject("user_id"));
        h.setName(rs.getString("name"));
        h.setType(rs.getString("type"));
        h.setUnit(rs.getString("unit"));

        BigDecimal target = rs.getBigDecimal("daily_target");
        h.setDailyTarget(target);

        h.setCategory(rs.getString("category"));

        Timestamp ts = rs.getTimestamp("created_at");
        if (ts != null) {
            h.setCreatedAt(ts.toInstant().atOffset(ZoneOffset.UTC));
        }
        return h;
    }
}
