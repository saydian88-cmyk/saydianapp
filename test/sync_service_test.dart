import 'package:flutter_test/flutter_test.dart';
import 'package:saydian_app/domain/models.dart';
import 'package:saydian_app/services/api_client.dart';
import 'package:saydian_app/services/local_health_store.dart';
import 'package:saydian_app/services/sync_service.dart';

void main() {
  test('uploads 1000 offline records once without duplicates', () async {
    final store = MemoryHealthStore();
    final api = _AcceptingApi();
    final service = HealthSyncService(store, api);
    await store.initialize();

    final records = List.generate(
      1000,
      (index) => HealthRecord(
        id: 'record-$index',
        metric: HealthMetric.heartRate,
        values: {'value': 60 + index % 40},
        unit: 'bpm',
        measuredAt: DateTime.utc(2026, 7, 29).add(Duration(minutes: index)),
        timezone: '+08:00',
        deviceId: 'device-1',
        firmwareVersion: '1.0.0',
        quality: 'good',
        source: MeasurementSource.wearable,
        rawVersion: 1,
      ),
    );
    await store.upsert(records);
    await store.upsert(records);

    final outcome = await service.synchronizeNow();

    expect(outcome.uploaded, 1000);
    expect(outcome.rejected, 0);
    expect(api.receivedIds, hasLength(1000));
    expect(await store.pending(), isEmpty);
  });

  test('keeps the queue when the backend batch endpoint is absent', () async {
    final store = MemoryHealthStore();
    final service = HealthSyncService(store, _UnconfiguredApi());
    await store.upsert([
      HealthRecord(
        id: 'record-1',
        metric: HealthMetric.steps,
        values: const {'value': 1000},
        unit: '步',
        measuredAt: DateTime.utc(2026, 7, 29),
        timezone: '+08:00',
        deviceId: 'device-1',
        firmwareVersion: '1.0.0',
        quality: 'good',
        source: MeasurementSource.wearable,
        rawVersion: 1,
      ),
    ]);

    final outcome = await service.synchronizeNow();

    expect(outcome.uploaded, 0);
    expect(outcome.message, contains('未配置'));
    expect(await store.pending(), hasLength(1));
  });
}

class _AcceptingApi extends _BaseFakeApi {
  final Set<String> receivedIds = {};

  @override
  Future<BatchUploadResult> uploadHealthBatch(SyncBatch batch) async {
    final accepted = batch.records.map((record) => record.id).toSet();
    receivedIds.addAll(accepted);
    return BatchUploadResult(
      acceptedIds: accepted,
      rejected: const {},
      nextCursor: 'cursor-${receivedIds.length}',
    );
  }
}

class _UnconfiguredApi extends _BaseFakeApi {
  @override
  Future<BatchUploadResult> uploadHealthBatch(SyncBatch batch) {
    throw const FeatureNotConfiguredException('批量健康同步接口未配置');
  }
}

abstract class _BaseFakeApi implements SaydianApi {
  @override
  Future<Map<String, Object?>> addCare(String mobile) async => const {};

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<List<Map<String, Object?>>> getCareMembers() async => const [];

  @override
  Future<Session> login(String username, String password) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<Session> register(String mobile, String password) =>
      throw UnimplementedError();
}
