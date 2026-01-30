package dao;

import config.DatabaseConfig;
import model.User;

import java.sql.*;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;

public class UserDAO {
    public User insert(User user) throws SQLException {
        String sql = "INSERT INTO users (id, name, email, password, created_at) " +
                "VALUES (?, ?, ?, ?, ?)";

        if (user.getId() == null) {
            user.setId(UUID.randomUUID());
        }
        if (user.getCreatedAt() == null) {
            user.setCreatedAt(OffsetDateTime.now(ZoneOffset.UTC));
        }

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, user.getId());
            ps.setString(2, user.getName());
            ps.setString(3, user.getEmail());
            ps.setString(4, user.getPassword());
            ps.setObject(5, user.getCreatedAt());

            ps.executeUpdate();
        }

        return user;
    }

    public Optional<User> findByEmail(String email) throws SQLException {
        String sql = "SELECT id, name, email, password, created_at FROM users WHERE email = ?";

        try (Connection conn = DatabaseConfig.getConnection()){
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, email);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                User u = mapRow(rs);
                return Optional.of(u);
            }
        }
        catch (SQLException e) {
            e.printStackTrace();
        }

        return Optional.empty();
    }

    public Optional<User> findById(UUID id) throws SQLException {
        String sql = "SELECT id, name, email, password, created_at FROM users WHERE id = ?";

        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setObject(1, id);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(mapRow(rs));
                }
            }
        }
        return Optional.empty();
    }

    private User mapRow(ResultSet rs) throws SQLException {
        User u = new User();
        u.setId((UUID) rs.getObject("id"));
        u.setName(rs.getString("name"));
        u.setEmail(rs.getString("email"));
        u.setPassword(rs.getString("password"));

        Timestamp ts = rs.getTimestamp("created_at");
        if (ts != null) {
            u.setCreatedAt(ts.toInstant().atOffset(ZoneOffset.UTC));
        }
        return u;
    }
}
