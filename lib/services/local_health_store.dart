import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../domain/models.dart';
import 'secure_vault.dart';

abstract interface class HealthStore {
  Future<void> initialize();
  Future<void> upsert(List<HealthRecord> records);
  Future<List<HealthRecord>> recent({int limit = 200});
  Future<List<HealthRecord>> pending({int limit = 200});
  Future<void> markSynced(Iterable<String> ids);
  Future<String?> readCursor();
  Future<void> writeCursor(String cursor);
  Future<void> close();
}

class EncryptedHealthStore implements HealthStore {
  EncryptedHealthStore(this._vault);

  final SessionVault _vault;
  Database? _database;

  Database get _db {
    final database = _database;
    if (database == null) {
      throw StateError('Health store has not been initialized');
    }
    return database;
  }

  @override
  Future<void> initialize() async {
    if (_database != null) return;
    final directory = await getApplicationSupportDirectory();
    final file = path.join(directory.path, 'saydian_health_v1.db');
    final password = await _vault.databaseKey();
    _database = await openDatabase(
      file,
      password: password,
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE health_records (
            id TEXT PRIMARY KEY,
            metric TEXT NOT NULL,
            measured_at TEXT NOT NULL,
            payload TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await database.execute('''
          CREATE INDEX health_records_time
          ON health_records(measured_at DESC)
        ''');
        await database.execute('''
          CREATE TABLE metadata (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }

  @override
  Future<void> upsert(List<HealthRecord> records) async {
    if (records.isEmpty) return;
    await _db.transaction((transaction) async {
      for (final record in records) {
        await transaction.insert('health_records', {
          'id': record.id,
          'metric': record.metric.wireName,
          'measured_at': record.measuredAt.toUtc().toIso8601String(),
          'payload': record.encode(),
          'synced': 0,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  @override
  Future<List<HealthRecord>> recent({int limit = 200}) async {
    final rows = await _db.query(
      'health_records',
      columns: ['payload'],
      orderBy: 'measured_at DESC',
      limit: limit,
    );
    return _decodeRows(rows);
  }

  @override
  Future<List<HealthRecord>> pending({int limit = 200}) async {
    final rows = await _db.query(
      'health_records',
      columns: ['payload'],
      where: 'synced = 0',
      orderBy: 'measured_at ASC',
      limit: limit,
    );
    return _decodeRows(rows);
  }

  List<HealthRecord> _decodeRows(List<Map<String, Object?>> rows) => rows
      .map((row) => jsonDecode('${row['payload']}'))
      .whereType<Map>()
      .map(
        (value) => HealthRecord.fromJson(
          value.map((key, value) => MapEntry('$key', value)),
        ),
      )
      .toList();

  @override
  Future<void> markSynced(Iterable<String> ids) async {
    final values = ids.toSet().toList();
    if (values.isEmpty) return;
    final placeholders = List.filled(values.length, '?').join(',');
    await _db.update(
      'health_records',
      {'synced': 1},
      where: 'id IN ($placeholders)',
      whereArgs: values,
    );
  }

  @override
  Future<String?> readCursor() async {
    final rows = await _db.query(
      'metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['sync_cursor'],
      limit: 1,
    );
    return rows.isEmpty ? null : '${rows.first['value']}';
  }

  @override
  Future<void> writeCursor(String cursor) => _db.insert('metadata', {
    'key': 'sync_cursor',
    'value': cursor,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

class MemoryHealthStore implements HealthStore {
  final Map<String, HealthRecord> _records = {};
  final Set<String> _synced = {};
  String? _cursor;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> upsert(List<HealthRecord> records) async {
    for (final record in records) {
      _records.putIfAbsent(record.id, () => record);
    }
  }

  @override
  Future<List<HealthRecord>> recent({int limit = 200}) async {
    final values = _records.values.toList()
      ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
    return values.take(limit).toList();
  }

  @override
  Future<List<HealthRecord>> pending({int limit = 200}) async => _records.values
      .where((record) => !_synced.contains(record.id))
      .take(limit)
      .toList();

  @override
  Future<void> markSynced(Iterable<String> ids) async => _synced.addAll(ids);

  @override
  Future<String?> readCursor() async => _cursor;

  @override
  Future<void> writeCursor(String cursor) async => _cursor = cursor;

  @override
  Future<void> close() async {}
}
