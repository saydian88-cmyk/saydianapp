import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';

abstract interface class SessionVault {
  Future<Session?> readSession();
  Future<void> writeSession(Session session);
  Future<void> clearSession();
  Future<HealthWarningSettings> readHealthWarningSettings();
  Future<void> writeHealthWarningSettings(HealthWarningSettings settings);
  Future<List<Map<String, Object?>>> readShopCart();
  Future<void> writeShopCart(List<Map<String, Object?>> items);
  Future<String> databaseKey();
}

class SecureSessionVault implements SessionVault {
  SecureSessionVault([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'saydian.session.v1';
  static const _databaseKey = 'saydian.database.key.v1';
  static const _healthWarningKey = 'saydian.health-warning.v1';
  static const _shopCartKey = 'saydian.shop-cart.v1';

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
  Future<HealthWarningSettings> readHealthWarningSettings() async {
    final raw = await _storage.read(key: _healthWarningKey);
    if (raw == null || raw.isEmpty) return const HealthWarningSettings();
    try {
      final value = jsonDecode(raw);
      if (value is! Map) return const HealthWarningSettings();
      return HealthWarningSettings.fromJson(
        value.map((key, value) => MapEntry('$key', value)),
      );
    } on FormatException {
      return const HealthWarningSettings();
    }
  }

  @override
  Future<void> writeHealthWarningSettings(HealthWarningSettings settings) =>
      _storage.write(
        key: _healthWarningKey,
        value: jsonEncode(settings.toJson()),
      );

  @override
  Future<List<Map<String, Object?>>> readShopCart() async {
    final raw = await _storage.read(key: _shopCartKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final value = jsonDecode(raw);
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> writeShopCart(List<Map<String, Object?>> items) =>
      _storage.write(key: _shopCartKey, value: jsonEncode(items));

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
  HealthWarningSettings healthWarningSettings = const HealthWarningSettings();
  String key = 'test-database-key-that-is-long-enough';
  List<Map<String, Object?>> shopCart = const [];

  @override
  Future<void> clearSession() async => session = null;

  @override
  Future<String> databaseKey() async => key;

  @override
  Future<Session?> readSession() async => session;

  @override
  Future<HealthWarningSettings> readHealthWarningSettings() async =>
      healthWarningSettings;

  @override
  Future<List<Map<String, Object?>>> readShopCart() async => shopCart;

  @override
  Future<void> writeSession(Session value) async => session = value;

  @override
  Future<void> writeHealthWarningSettings(
    HealthWarningSettings settings,
  ) async => healthWarningSettings = settings;

  @override
  Future<void> writeShopCart(List<Map<String, Object?>> items) async =>
      shopCart = items;
}
