import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/focus_session.dart';

class StatsService {
  static const String _sessionsKey = 'focus_sessions';
  static final StatsService _instance = StatsService._internal();

  factory StatsService() => _instance;

  StatsService._internal();

  Future<void> saveSession(FocusSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> sessionsJson = prefs.getStringList(_sessionsKey) ?? [];
    sessionsJson.add(jsonEncode(session.toJson()));
    await prefs.setStringList(_sessionsKey, sessionsJson);
  }

  Future<List<FocusSession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> sessionsJson = prefs.getStringList(_sessionsKey) ?? [];
    return sessionsJson.map((s) => FocusSession.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
  }
}
