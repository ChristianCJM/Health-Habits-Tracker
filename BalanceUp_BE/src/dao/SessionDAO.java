package dao;

import config.DatabaseConfig;

import java.sql.*;
import java.time.OffsetDateTime;
import java.util.Optional;
import java.util.UUID;

public class SessionDAO {

    public void insert(UUID token, UUID userId, OffsetDateTime expiresAt) throws SQLException {
        String sql = "INSERT INTO sessions (token, user_id, expires_at) VALUES (?, ?, ?)";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setObject(1, token);
            ps.setObject(2, userId);
            ps.setObject(3, Timestamp.from(expiresAt.toInstant()));
            ps.executeUpdate();
        }
    }

    public Optional<UUID> findUserIdByToken(UUID token) throws SQLException {
        String sql = "SELECT user_id FROM sessions WHERE token = ? AND expires_at > now()";
        try (Connection conn = DatabaseConfig.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setObject(1, token);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return Optional.of(UUID.fromString(rs.getString("user_id")));
            }
        }
        return Optional.empty();
    }
}

