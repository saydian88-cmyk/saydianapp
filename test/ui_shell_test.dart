import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saydian_app/domain/models.dart';
import 'package:saydian_app/services/api_client.dart';
import 'package:saydian_app/services/app_controller.dart';
import 'package:saydian_app/services/local_health_store.dart';
import 'package:saydian_app/services/secure_vault.dart';
import 'package:saydian_app/services/wearable_bridge.dart';
import 'package:saydian_app/ui/app_theme.dart';
import 'package:saydian_app/ui/pages.dart';

void main() {
  testWidgets('core Lanhu-aligned tabs render at a phone viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = AppController(
      MemorySessionVault(),
      _NoopApi(),
      MemoryHealthStore(),
      _NoopWearable(),
    )..enterPreview();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildSaydianTheme(),
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => AppShell(controller: controller),
        ),
      ),
    );

    for (var tab = 0; tab < 5; tab++) {
      controller.selectTab(tab);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'tab $tab overflowed');
    }
  });
}

class _NoopApi implements SaydianApi {
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

  @override
  Future<BatchUploadResult> uploadHealthBatch(SyncBatch batch) =>
      throw UnimplementedError();
}

class _NoopWearable implements WearableBridge {
  @override
  Future<void> connect(String deviceId) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Stream<WearableEvent> get events => const Stream.empty();

  @override
  Future<DeviceCapabilities> getCapabilities() async =>
      const DeviceCapabilities(metrics: {});

  @override
  Future<List<DeviceInfo>> scanDevices() async => const [];

  @override
  Future<void> startMeasurement(HealthMetric metric) async {}

  @override
  Future<void> stopMeasurement(HealthMetric metric) async {}

  @override
  Future<List<HealthRecord>> syncHealthData({String? cursor}) async => const [];
}
