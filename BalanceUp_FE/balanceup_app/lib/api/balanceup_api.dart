import 'dart:convert';
import 'package:balanceup_app/api/authresponse.dart';
import 'package:balanceup_app/session.dart';
import 'package:http/http.dart' as http;

class BalanceUpApi {
  final String baseUrl;

  BalanceUpApi({required this.baseUrl});

  Map<String, String> _headers() {
  return {
    'Content-Type': 'application/json',
    if (AppSession.token != null)
      'Authorization': 'Bearer ${AppSession.token}',
  };
}


  Future<AuthResponse> login(String email, String password) async {
  final res = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    headers: _headers(),
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception('Login failed: ${res.body}');
  }

  final data = jsonDecode(res.body);
  return AuthResponse.fromJson(data);
}

Future<AuthResponse> register(String name, String email, String password) async {
  final res = await http.post(
    Uri.parse('$baseUrl/auth/register'),
    headers: _headers(),
    body: jsonEncode({
      'name': name,
      'email': email,
      'password': password,
    }),
  );

  if (res.statusCode != 201) {
    throw Exception('Register failed: ${res.body}');
  }

  final data = jsonDecode(res.body);
  return AuthResponse.fromJson(data);
}


  Future<List<Habit>> getHabits() async {
    final uri = Uri.parse('$baseUrl/habits');
    final res = await http.get(uri, headers: _headers());

    if (res.statusCode != 200) {
      throw Exception('GET /habits failed: ${res.statusCode} ${res.body}');
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data.map((e) => Habit.fromJson(e)).toList();
  }

  Future<Habit> createHabit(CreateHabitRequest req) async {
    final uri = Uri.parse('$baseUrl/habits');
    final res = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(req.toJson()),
    );

    if (res.statusCode != 201) {
      throw Exception('POST /habits failed: ${res.statusCode} ${res.body}');
    }

    return Habit.fromJson(jsonDecode(res.body));
  }

  Future<List<HabitEntry>> getEntries({
    required String habitId,
    String? from, // YYYY-MM-DD
    String? to,   // YYYY-MM-DD
  }) async {
    final qp = <String, String>{};
    if (from != null) qp['from'] = from;
    if (to != null) qp['to'] = to;

    final uri = Uri.parse('$baseUrl/habits/$habitId/entries')
        .replace(queryParameters: qp.isEmpty ? null : qp);

    final res = await http.get(uri,headers: _headers(),);

    if (res.statusCode != 200) {
      throw Exception('GET /habits/$habitId/entries failed: ${res.statusCode} ${res.body}');
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data.map((e) => HabitEntry.fromJson(e)).toList();
  }

  Future<HabitEntry> createEntry({
    required String habitId,
    required CreateEntryRequest req,
  }) async {
    final uri = Uri.parse('$baseUrl/habits/$habitId/entries');
    final res = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(req.toJson()),
    );

    if (res.statusCode != 201) {
      throw Exception('POST /habits/$habitId/entries failed: ${res.statusCode} ${res.body}');
    }

    return HabitEntry.fromJson(jsonDecode(res.body));
  }

  Future<List<DashboardHabit>> getDashboard() async {
    final uri = Uri.parse('$baseUrl/dashboard');
    final res = await http.get(uri, headers: _headers(),);

    if (res.statusCode != 200) {
      throw Exception('GET /dashboard failed: ${res.statusCode} ${res.body}');
    }

    final List<dynamic> data = jsonDecode(res.body);
    return data.map((e) => DashboardHabit.fromJson(e)).toList();
  }
}

/* ---------- Models ---------- */

class Habit {
  final String id;
  final String name;
  final String type;
  final String? unit;
  final num? dailyTarget;
  final String? category;

  Habit({
    required this.id,
    required this.name,
    required this.type,
    this.unit,
    this.dailyTarget,
    this.category,
  });

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      unit: json['unit'] as String?,
      dailyTarget: json['dailyTarget'] as num?,
      category: json['category'] as String?,
    );
  }
}

class CreateHabitRequest {
  final String name;
  final String type;
  final String? unit;
  final num? dailyTarget;
  final String? category;

  CreateHabitRequest({
    required this.name,
    required this.type,
    this.unit,
    this.dailyTarget,
    this.category,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'unit': unit,
        'dailyTarget': dailyTarget,
        'category': category,
      };
}

class HabitEntry {
  final String id;
  final String habitId;
  final String entryDate; // YYYY-MM-DD
  final num? valueNumeric;
  final bool? valueBool;

  HabitEntry({
    required this.id,
    required this.habitId,
    required this.entryDate,
    this.valueNumeric,
    this.valueBool,
  });

  factory HabitEntry.fromJson(Map<String, dynamic> json) {
    return HabitEntry(
      id: json['id'] as String,
      habitId: json['habitId'] as String,
      entryDate: json['entryDate'] as String,
      valueNumeric: json['valueNumeric'] as num?,
      valueBool: json['valueBool'] as bool?,
    );
  }
}

class CreateEntryRequest {
  final String entryDate; // YYYY-MM-DD
  final num? valueNumeric;
  final bool? valueBool;

  CreateEntryRequest({
    required this.entryDate,
    this.valueNumeric,
    this.valueBool,
  });

  Map<String, dynamic> toJson() => {
        'entryDate': entryDate,
        'valueNumeric': valueNumeric,
        'valueBool': valueBool,
      };
}

class DashboardHabit extends Habit {
  final num todayCurrent;
  final num todayProgress;

  DashboardHabit({
    required super.id,
    required super.name,
    required super.type,
    super.unit,
    super.dailyTarget,
    super.category,
    required this.todayCurrent,
    required this.todayProgress,
  });

  factory DashboardHabit.fromJson(Map<String, dynamic> json) {
    return DashboardHabit(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      unit: json['unit'] as String?,
      dailyTarget: json['dailyTarget'] as num?,
      category: json['category'] as String?,
      todayCurrent: (json['todayCurrent'] as num?) ?? 0,
      todayProgress: (json['todayProgress'] as num?) ?? 0,
    );
  }
}

