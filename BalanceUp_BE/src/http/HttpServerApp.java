package http;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonPrimitive;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import dao.HabitDAO;
import dao.HabitEntryDAO;
import dao.SessionDAO;
import dao.UserDAO;
import model.Habit;
import model.HabitEntry;
import model.User;
import utils.PasswordUtil;

import java.io.*;
import java.math.BigDecimal;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.*;
import java.math.BigDecimal;


public class HttpServerApp {

    private final HabitDAO habitDAO;
    private final UserDAO userDAO;
    private final HabitEntryDAO habitEntryDAO;
    private final SessionDAO sessionDAO = new SessionDAO();
    private final Gson gson;

    public HttpServerApp() {
        this.habitDAO = new HabitDAO();
        this.userDAO = new UserDAO();
        this.habitEntryDAO = new HabitEntryDAO();
        this.gson = new GsonBuilder()
                .registerTypeAdapter(LocalDate.class,
                        (com.google.gson.JsonSerializer<LocalDate>) (src, typeOfSrc, context) -> new JsonPrimitive(src.toString()))
                .registerTypeAdapter(LocalDate.class,
                        (com.google.gson.JsonDeserializer<LocalDate>) (json, typeOfT, context) -> LocalDate.parse(json.getAsString()))
                .registerTypeAdapter(OffsetDateTime.class,
                        (com.google.gson.JsonSerializer<OffsetDateTime>) (src, typeOfSrc, context) -> new JsonPrimitive(src.toString()))
                .registerTypeAdapter(OffsetDateTime.class,
                        (com.google.gson.JsonDeserializer<OffsetDateTime>) (json, typeOfT, context) -> OffsetDateTime.parse(json.getAsString()))
                .create();

    }

    public void start(int port) throws IOException {
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);

        server.createContext("/habits", this::handleHabits);
        server.createContext("/dashboard", this::handleDashboard);
        server.createContext("/auth/register", this::handleRegister);
        server.createContext("/auth/login", this::handleLogin);



        server.setExecutor(null);
        server.start();
        System.out.println("HTTP server started on port " + port);
    }

    private void handleDashboard(com.sun.net.httpserver.HttpExchange exchange) throws java.io.IOException {
        try {
            if (!"GET".equalsIgnoreCase(exchange.getRequestMethod())) {
                exchange.sendResponseHeaders(405, -1);
                return;
            }

            //User user = getOrCreateTestUser();
            UUID userId = requireUserId(exchange);
            if (userId == null) return;
            List<Habit> habits = habitDAO.findByUserId(userId);

            LocalDate today = LocalDate.now();
            List<HabitEntry> todayEntries =
                    habitEntryDAO.findByUserIdAndDate(userId, today);

            Map<UUID, BigDecimal> sumByHabit = new HashMap<>();
            for (var e : todayEntries) {
                BigDecimal v = e.getValueNumeric() != null ? e.getValueNumeric() : BigDecimal.ZERO;
                sumByHabit.merge(e.getHabitId(), v, BigDecimal::add);
            }

            List<Map<String, Object>> items = new ArrayList<>();
            for (Habit h : habits) {
                BigDecimal current = sumByHabit.getOrDefault(h.getId(), BigDecimal.ZERO);

                BigDecimal goal = h.getDailyTarget() != null ? h.getDailyTarget() : BigDecimal.ZERO;
                double progress = 0.0;
                if (goal.compareTo(BigDecimal.ZERO) > 0) {
                    progress = current.divide(goal, 6, java.math.RoundingMode.HALF_UP).doubleValue();
                    if (progress < 0) progress = 0;
                    if (progress > 1) progress = 1;
                }

                Map<String, Object> obj = new LinkedHashMap<>();
                obj.put("id", h.getId());
                obj.put("name", h.getName());
                obj.put("type", h.getType());
                obj.put("unit", h.getUnit());
                obj.put("dailyTarget", h.getDailyTarget());
                obj.put("category", h.getCategory());

                obj.put("todayCurrent", current);
                obj.put("todayProgress", progress);

                items.add(obj);
            }

            String json = gson.toJson(items);
            sendJsonResponse(exchange, 200, json);

        } catch (Exception e) {
            e.printStackTrace();
            String json = "{\"error\":\"" + e.getClass().getSimpleName() + ": " + e.getMessage() + "\"}";
            byte[] bytes = json.getBytes(java.nio.charset.StandardCharsets.UTF_8);
            exchange.getResponseHeaders().add("Content-Type", "application/json; charset=utf-8");
            exchange.sendResponseHeaders(500, bytes.length);
            try (var os = exchange.getResponseBody()) { os.write(bytes); }
        } finally {
            exchange.close();
        }
    }

    private void handleHabitEntriesRoute(HttpExchange exchange, String path) throws IOException, SQLException {
        String[] parts = path.split("/");
        if (parts.length == 4 && "habits".equals(parts[1]) && "entries".equals(parts[3])) {
            String habitIdStr = parts[2];

            java.util.UUID habitId;
            try {
                habitId = java.util.UUID.fromString(habitIdStr);
            } catch (IllegalArgumentException e) {
                exchange.sendResponseHeaders(400, -1); // Bad Request
                return;
            }

            String method = exchange.getRequestMethod();
            if ("GET".equalsIgnoreCase(method)) {
                handleGetHabitEntries(exchange, habitId);
            } else if ("POST".equalsIgnoreCase(method)) {
                handlePostHabitEntry(exchange, habitId);
            } else {
                exchange.sendResponseHeaders(405, -1);
            }
        } else {
            exchange.sendResponseHeaders(404, -1);
        }
    }

    private void handleHabits(HttpExchange exchange) throws IOException {
        String path = exchange.getRequestURI().getPath(); // ex: /habits ou /habits/{id}/entries
        try {
            if ("/habits".equals(path)) {
                String method = exchange.getRequestMethod();
                if ("GET".equalsIgnoreCase(method)) {
                    handleGetHabits(exchange);
                } else if ("POST".equalsIgnoreCase(method)) {
                    handlePostHabit(exchange);
                } else {
                    exchange.sendResponseHeaders(405, -1);
                }
            } else if (path.startsWith("/habits/")) {
                handleHabitEntriesRoute(exchange, path);
            } else {
                exchange.sendResponseHeaders(404, -1);
            }
        } catch (Exception e) {
            e.printStackTrace();
            exchange.sendResponseHeaders(500, -1);
        } finally {
            exchange.close();
        }
    }

    private User getOrCreateTestUser() throws SQLException {
        String email = "test@example.com";
        return userDAO.findByEmail(email).orElseGet(() -> {
            User u = new User();
            u.setName("Test User");
            u.setEmail(email);
            u.setPassword("dummy-hash");
            try {
                return userDAO.insert(u);
            } catch (SQLException e) {
                throw new RuntimeException(e);
            }
        });
    }

    private void handleGetHabitEntries(HttpExchange exchange, java.util.UUID habitId) throws IOException, SQLException {
        String query = exchange.getRequestURI().getQuery();
        LocalDate today = LocalDate.now();
        LocalDate from = today.minusDays(6);
        LocalDate to = today;

        if (query != null) {
            String fromStr = getQueryParam(query, "from");
            String toStr = getQueryParam(query, "to");
            if (fromStr != null && !fromStr.isBlank()) {
                from = LocalDate.parse(fromStr);
            }
            if (toStr != null && !toStr.isBlank()) {
                to = LocalDate.parse(toStr);
            }
        }

        List<HabitEntry> entries = habitEntryDAO.findByHabitIdAndDateRange(habitId, from, to);

        List<HabitEntryResponse> responses = entries.stream()
                .map(HabitEntryResponse::fromModel)
                .toList();

        String json = gson.toJson(responses);
        sendJsonResponse(exchange, 200, json);
    }

    private void handlePostHabitEntry(HttpExchange exchange, java.util.UUID habitId) throws IOException, SQLException {
        String body = readRequestBody(exchange);

        HabitEntryCreateRequest request = gson.fromJson(body, HabitEntryCreateRequest.class);

        HabitEntry entry = new HabitEntry();
        entry.setHabitId(habitId);
        entry.setEntryDate(LocalDate.parse(request.getEntryDate()));
        entry.setValueNumeric(request.getValueNumeric());
        entry.setValueBool(request.getValueBool());

        HabitEntry saved = habitEntryDAO.insert(entry);
        HabitEntryResponse response = HabitEntryResponse.fromModel(saved);

        String json = gson.toJson(response);
        sendJsonResponse(exchange, 201, json);
    }

    private void handleGetHabits(HttpExchange exchange) throws Exception {
        //User user = getOrCreateTestUser();
        UUID userId = requireUserId(exchange);
        if (userId == null) return;
        var habits = habitDAO.findByUserId(userId);

        List<HabitResponse> responses = habits.stream()
                .map(HabitResponse::fromModel)
                .toList();

        String json = gson.toJson(responses);
        sendJsonResponse(exchange, 200, json);
    }

    private void handlePostHabit(HttpExchange exchange) throws Exception {
        String body = readRequestBody(exchange);

        HabitCreateRequest request = gson.fromJson(body, HabitCreateRequest.class);

        //User user = getOrCreateTestUser();
        UUID userId = requireUserId(exchange);
        if (userId == null) return;

        Habit habit = new Habit();
        habit.setUserId(userId);
        habit.setName(request.getName());
        habit.setType(request.getType());
        habit.setUnit(request.getUnit());
        habit.setDailyTarget(request.getDailyTarget());
        habit.setCategory(request.getCategory());

        Habit saved = habitDAO.insert(habit);
        HabitResponse response = HabitResponse.fromModel(saved);

        String json = gson.toJson(response);
        sendJsonResponse(exchange, 201, json);
    }

    private String getQueryParam(String query, String key) {
        if (query == null) return null;
        String[] parts = query.split("&");
        for (String part : parts) {
            String[] kv = part.split("=", 2);
            if (kv.length == 2 && kv[0].equals(key)) {
                return java.net.URLDecoder.decode(kv[1], java.nio.charset.StandardCharsets.UTF_8);
            }
        }
        return null;
    }

    private String readRequestBody(HttpExchange exchange) throws IOException {
        try (InputStream is = exchange.getRequestBody()) {
            return new String(is.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    private void sendJsonResponse(HttpExchange exchange, int status, String json) throws IOException {
        byte[] bytes = json.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().add("Content-Type", "application/json; charset=utf-8");
        exchange.sendResponseHeaders(status, bytes.length);
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(bytes);
        }
    }

    private void handleRegister(HttpExchange exchange) throws IOException {
        try {
            if (!"POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                exchange.sendResponseHeaders(405, -1);
                return;
            }

            RegisterRequest req = gson.fromJson(readRequestBody(exchange), RegisterRequest.class);
            if (req == null || req.email == null || req.password == null || req.name == null) {
                sendJsonResponse(exchange, 400, "{\"error\":\"Missing fields\"}");
                return;
            }

            String email = req.email.trim().toLowerCase();

            if (userDAO.findByEmail(email).isPresent()) {
                sendJsonResponse(exchange, 409, "{\"error\":\"Email already exists\"}");
                return;
            }

            User u = new User();
            u.setId(UUID.randomUUID());
            u.setName(req.name.trim());
            u.setEmail(email);
            u.setPassword(PasswordUtil.hashPassword(req.password)); // ✅ stores hash in 'password'
            u.setCreatedAt(OffsetDateTime.now());

            u = userDAO.insert(u);

            UUID token = UUID.randomUUID();
            sessionDAO.insert(token, u.getId(), OffsetDateTime.now().plusDays(30));

            sendJsonResponse(exchange, 201, gson.toJson(new AuthResponse(token.toString(), u.getId().toString())));
        } catch (Exception e) {
            e.printStackTrace();
            sendJsonResponse(exchange, 500, "{\"error\":\"" + e.getMessage() + "\"}");
        } finally {
            exchange.close();
        }
    }

    private void handleLogin(HttpExchange exchange) throws IOException {
        try {
            if (!"POST".equalsIgnoreCase(exchange.getRequestMethod())) {
                exchange.sendResponseHeaders(405, -1);
                return;
            }

            LoginRequest req = gson.fromJson(readRequestBody(exchange), LoginRequest.class);
            if (req == null || req.email == null || req.password == null) {
                sendJsonResponse(exchange, 400, "{\"error\":\"Missing fields\"}");
                return;
            }

            String email = req.email.trim().toLowerCase();
            Optional<User> opt = userDAO.findByEmail(email);

            if (opt.isEmpty()) {
                sendJsonResponse(exchange, 401, "{\"error\":\"Invalid credentials\"}");
                return;
            }

            User u = opt.get();

            if (!PasswordUtil.verify(req.password, u.getPassword())) { // ✅
                sendJsonResponse(exchange, 401, "{\"error\":\"Invalid credentials\"}");
                return;
            }

            UUID token = UUID.randomUUID();
            sessionDAO.insert(token, u.getId(), OffsetDateTime.now().plusDays(30));

            sendJsonResponse(exchange, 200, gson.toJson(new AuthResponse(token.toString(), u.getId().toString())));
        } catch (Exception e) {
            e.printStackTrace();
            sendJsonResponse(exchange, 500, "{\"error\":\"" + e.getMessage() + "\"}");
        } finally {
            exchange.close();
        }
    }

    private UUID requireUserId(HttpExchange exchange) throws Exception {
        String auth = exchange.getRequestHeaders().getFirst("Authorization");
        if (auth == null || !auth.startsWith("Bearer ")) {
            sendJsonResponse(exchange, 401, "{\"error\":\"Missing token\"}");
            return null;
        }

        String tokenStr = auth.substring("Bearer ".length()).trim();
        UUID token;
        try { token = UUID.fromString(tokenStr); }
        catch (IllegalArgumentException e) {
            sendJsonResponse(exchange, 401, "{\"error\":\"Invalid token\"}");
            return null;
        }

        Optional<UUID> userId = sessionDAO.findUserIdByToken(token);
        if (userId.isEmpty()) {
            sendJsonResponse(exchange, 401, "{\"error\":\"Session expired\"}");
            return null;
        }
        return userId.get();
    }

}
