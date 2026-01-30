package http;

public class AuthResponse {
    String token;
    String userId;
    AuthResponse(String token, String userId) { this.token = token; this.userId = userId; }
}
