//TIP To <b>Run</b> code, press <shortcut actionId="Run"/> or
// click the <icon src="AllIcons.Actions.Execute"/> icon in the gutter.
import config.DatabaseConfig;
import dao.HabitDAO;
import dao.UserDAO;
import http.HttpServerApp;
import model.Habit;
import model.User;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.List;

public class Main {
    public static void main(String[] args) throws Exception {
        HttpServerApp app = new HttpServerApp();
        app.start(8080);
    }
}