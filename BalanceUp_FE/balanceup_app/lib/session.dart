class AppSession {
  static String? token;
  static bool get isLoggedIn => token != null;

  static void clear() {
    token = null;
  }
}
