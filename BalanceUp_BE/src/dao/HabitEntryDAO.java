package dao;

import config.DatabaseConfig;
import model.HabitEntry;

import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class HabitEntryDAO {

    public HabitEntry insert(HabitEntry entry) throws SQLException {
        String sql = "INSERT INTO habit_entries " +
                "(id, habit_id, entry_date, value_numeric, value_boolean, created_at) " +
                "VALUES (?, ?, ?, ?, ?, ?)";

        if (entry.getId() == null) {
            entry.setId(UUID.randomUUID());
        }
        if (entry.getCreatedAt() == null) {
            entry.setCreatedAt(OffsetDateTime.now(ZoneOffset.UTC));
        }

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, entry.getId());
            ps.setObject(2, entry.getHabitId());
            ps.setDate(3, Date.valueOf(entry.getEntryDate()));

            BigDecimal numeric = entry.getValueNumeric();
            if (numeric != null) {
                ps.setBigDecimal(4, numeric);
            } else {
                ps.setNull(4, Types.NUMERIC);
            }

            if (entry.getValueBool() != null) {
                ps.setBoolean(5, entry.getValueBool());
            } else {
                ps.setNull(5, Types.BOOLEAN);
            }

            ps.setObject(6, entry.getCreatedAt());

            ps.executeUpdate();
        }

        return entry;
    }

    public List<HabitEntry> findByHabitIdAndDateRange(UUID habitId, LocalDate from, LocalDate to) throws SQLException {
        String sql = "SELECT id, habit_id, entry_date, value_numeric, value_boolean, created_at " +
                "FROM habit_entries " +
                "WHERE habit_id = ? AND entry_date BETWEEN ? AND ? " +
                "ORDER BY entry_date";

        List<HabitEntry> result = new ArrayList<>();

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, habitId);
            ps.setDate(2, Date.valueOf(from));
            ps.setDate(3, Date.valueOf(to));

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(mapRow(rs));
                }
            }
        }

        return result;
    }

    public List<HabitEntry> findByUserIdAndDate(UUID userId, LocalDate date) throws SQLException {
        String sql =
                "SELECT he.id, he.habit_id, he.entry_date, he.value_numeric, he.value_boolean, he.created_at " +
                        "FROM habit_entries he " +
                        "JOIN habits h ON h.id = he.habit_id " +
                        "WHERE h.user_id = ? AND he.entry_date = ? " +
                        "ORDER BY he.entry_date";

        List<HabitEntry> result = new ArrayList<>();

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, userId);
            ps.setDate(2, Date.valueOf(date));

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(mapRow(rs));
                }
            }
        }

        return result;
    }


    private HabitEntry mapRow(ResultSet rs) throws SQLException {
        HabitEntry e = new HabitEntry();
        e.setId((UUID) rs.getObject("id"));
        e.setHabitId((UUID) rs.getObject("habit_id"));

        Date date = rs.getDate("entry_date");
        if (date != null) {
            e.setEntryDate(date.toLocalDate());
        }

        e.setValueNumeric(rs.getBigDecimal("value_numeric"));

        Boolean bool = (Boolean) rs.getObject("value_boolean"); // getObject permite null
        e.setValueBool(bool);

        Timestamp ts = rs.getTimestamp("created_at");
        if (ts != null) {
            e.setCreatedAt(ts.toInstant().atOffset(ZoneOffset.UTC));
        }

        return e;
    }
}
