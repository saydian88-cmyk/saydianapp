import '../domain/models.dart';
import 'api_client.dart';
import 'local_health_store.dart';

class SyncOutcome {
  const SyncOutcome({
    required this.uploaded,
    required this.rejected,
    this.message,
  });

  final int uploaded;
  final int rejected;
  final String? message;
}

class HealthSyncService {
  const HealthSyncService(this._store, this._api);

  final HealthStore _store;
  final SaydianApi _api;

  Future<SyncOutcome> synchronizeNow() async {
    var uploaded = 0;
    var rejected = 0;
    while (true) {
      final records = await _store.pending(limit: 200);
      if (records.isEmpty) {
        return SyncOutcome(uploaded: uploaded, rejected: rejected);
      }
      final cursor = await _store.readCursor();
      try {
        final result = await _api.uploadHealthBatch(
          SyncBatch(cursor: cursor, records: records),
        );
        await _store.markSynced(result.acceptedIds);
        if (result.nextCursor != null) {
          await _store.writeCursor(result.nextCursor!);
        }
        uploaded += result.acceptedIds.length;
        rejected += result.rejected.length;
        if (result.acceptedIds.isEmpty) {
          return SyncOutcome(
            uploaded: uploaded,
            rejected: rejected,
            message: '服务器未接收任何记录，已保留本地队列',
          );
        }
      } on FeatureNotConfiguredException catch (error) {
        return SyncOutcome(
          uploaded: uploaded,
          rejected: rejected,
          message: error.message,
        );
      }
    }
  }
}
