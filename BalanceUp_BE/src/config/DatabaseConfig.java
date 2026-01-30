package config;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConfig {
    //private static final String URL = "jdbc:postgresql://db.kwhjiftunsytlvnkffgu.supabase.co:5432/postgres";
    //private static final String USER = "postgres";
    //private static final String PASSWORD = "R9mmaqUnz8asOrwu"; // coloque aqui

    private static final String URL = "jdbc:postgresql://aws-1-eu-west-3.pooler.supabase.com:5432/postgres?user=postgres.kwhjiftunsytlvnkffgu&password=R9mmaqUnz8asOrwu";

    static {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("PostgreSQL driver not found", e);
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL);
    }

}
