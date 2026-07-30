import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';

abstract interface class SessionVault {
  Future<Session?> readSession();
  Future<void> writeSession(Session session);
  Future<void> clearSession();
  Future<String> databaseKey();
}

class SecureSessionVault implements SessionVault {
  SecureSessionVault([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'saydian.session.v1';
  static const _databaseKey = 'saydian.database.key.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<Session?> readSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return null;
      return Session.fromJson(
        value.map((key, value) => MapEntry('$key', value)),
      );
    } on FormatException {
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> writeSession(Session session) =>
      _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));

  @override
  Future<void> clearSession() => _storage.delete(key: _sessionKey);

  @override
  Future<String> databaseKey() async {
    final existing = await _storage.read(key: _databaseKey);
    if (existing != null && existing.length >= 24) return existing;
    final generated = const Uuid().v4() + const Uuid().v4();
    await _storage.write(key: _databaseKey, value: generated);
    return generated;
  }
}

class MemorySessionVault implements SessionVault {
  Session? session;
  String key = 'test-database-key-that-is-long-enough';

  @override
  Future<void> clearSession() async => session = null;

  @override
  Future<String> databaseKey() async => key;

  @override
  Future<Session?> readSession() async => session;

  @override
  Future<void> writeSession(Session value) async => session = value;
}
