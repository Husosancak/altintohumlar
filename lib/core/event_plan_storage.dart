import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/haber.dart';

class EventPlanStorage {
  static const String _storageKey = 'event_plans_v1';

  static Future<Map<String, dynamic>> _readRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static Future<Map<String, dynamic>> readAll() async {
    return _readRaw();
  }

  static Future<Map<String, dynamic>?> readById(String eventId) async {
    final plans = await _readRaw();
    final value = plans[eventId];
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  static Future<void> upsert({
    required Haber haber,
    required String status,
    required String note,
  }) async {
    final plans = await _readRaw();
    final prefs = await SharedPreferences.getInstance();
    final eventId = haber.id.toString();
    final trimmedNote = note.trim();

    final hasStatus = status != 'none';
    final hasNote = trimmedNote.isNotEmpty;

    // Remove empty plans so this storage only keeps user-meaningful actions.
    if (!hasStatus && !hasNote) {
      plans.remove(eventId);
      await prefs.setString(_storageKey, jsonEncode(plans));
      return;
    }

    plans[eventId] = <String, dynamic>{
      'id': eventId,
      'status': status,
      'note': trimmedNote,
      'updatedAt': DateTime.now().toIso8601String(),
      'title': haber.baslik,
      'date': haber.tarih,
      'time': haber.saat,
      'image': haber.resim,
    };

    await prefs.setString(_storageKey, jsonEncode(plans));
  }

  static Future<void> remove(String eventId) async {
    final plans = await _readRaw();
    plans.remove(eventId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(plans));
  }
}
