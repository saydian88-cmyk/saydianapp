import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart' as platform_info;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/device_state_machine.dart';
import '../domain/models.dart';
import 'api_client.dart';
import 'local_health_store.dart';
import 'secure_vault.dart';
import 'sync_service.dart';
import 'wearable_bridge.dart';

class AppController extends ChangeNotifier {
  AppController(this._vault, this._api, this._healthStore, this._wearable)
    : _syncService = HealthSyncService(_healthStore, _api);

  factory AppController.production() {
    final vault = SecureSessionVault();
    return AppController(
      vault,
      SaydianApiClient(vault),
      EncryptedHealthStore(vault),
      MethodChannelWearableBridge(),
    );
  }

  final SessionVault _vault;
  final SaydianApi _api;
  final HealthStore _healthStore;
  final WearableBridge _wearable;
  final HealthSyncService _syncService;
  final DeviceStateMachine deviceMachine = DeviceStateMachine();

  StreamSubscription<WearableEvent>? _wearableEvents;
  StreamSubscription<DeviceConnectionState>? _deviceStates;
  StreamSubscription<List<ConnectivityResult>>? _connectivity;
  bool _syncing = false;

  bool isBooting = true;
  bool isBusy = false;
  bool isPreviewMode = false;
  Session? session;
  int selectedTab = 0;
  String? errorMessage;
  String storageStatus = '正在初始化';
  String sdkStatus = '等待检测';
  String syncStatus = '尚未同步';
  DeviceInfo? connectedDevice;
  DeviceCapabilities? capabilities;
  List<DeviceInfo> scannedDevices = const [];
  List<HealthRecord> healthRecords = const [];
  List<Map<String, Object?>> careMembers = const [];

  bool get isAuthenticated => session != null;
  DeviceConnectionState get deviceState => deviceMachine.state;

  Map<HealthMetric, HealthRecord> get latestByMetric {
    final result = <HealthMetric, HealthRecord>{};
    for (final record in healthRecords) {
      result.putIfAbsent(record.metric, () => record);
    }
    return result;
  }

  Future<void> initialize() async {
    _deviceStates = deviceMachine.changes.listen((_) => notifyListeners());
    _connectivity = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none) &&
          session != null) {
        unawaited(synchronizeCloud());
      }
    });
    try {
      await _healthStore.initialize();
      storageStatus = '本地加密存储已就绪';
      healthRecords = await _healthStore.recent();
    } catch (_) {
      storageStatus = '本地加密存储未配置';
    }
    try {
      session = await _vault.readSession();
      if (session?.isExpired ?? false) {
        errorMessage = '登录已过期；Token 刷新接口未配置，请重新登录';
        await _vault.clearSession();
        session = null;
      }
    } catch (_) {
      errorMessage = '安全存储初始化失败';
    }
    try {
      _wearableEvents = _wearable.events.listen(
        _handleWearableEvent,
        onError: (_) {
          sdkStatus = 'Veepoo SDK 未配置';
          notifyListeners();
        },
      );
    } catch (_) {
      sdkStatus = 'Veepoo SDK 未配置';
    }
    isBooting = false;
    notifyListeners();
    if (session != null) {
      unawaited(refreshCare());
    }
  }

  Future<bool> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) {
      errorMessage = '请输入账号和密码';
      notifyListeners();
      return false;
    }
    return _guard(() async {
      session = await _api.login(username.trim(), password);
      isPreviewMode = false;
      await refreshCare();
    });
  }

  Future<bool> register(String mobile, String password) async {
    if (!RegExp(r'^1\d{10}$').hasMatch(mobile.trim())) {
      errorMessage = '请输入正确的中国大陆手机号';
      notifyListeners();
      return false;
    }
    if (password.length < 8) {
      errorMessage = '密码至少需要 8 位';
      notifyListeners();
      return false;
    }
    return _guard(() async {
      session = await _api.register(mobile.trim(), password);
      isPreviewMode = false;
    });
  }

  void enterPreview() {
    isPreviewMode = true;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    isBusy = true;
    notifyListeners();
    try {
      if (session != null) {
        await _api.logout();
      } else {
        await _vault.clearSession();
      }
    } on ApiException catch (error) {
      errorMessage = error.message;
    } finally {
      session = null;
      isPreviewMode = false;
      selectedTab = 0;
      isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAccount() => _guard(() async {
    if (session == null) {
      throw const ApiException('预览模式没有可注销的账号');
    }
    await _api.deleteAccount();
    session = null;
    isPreviewMode = false;
  });

  void selectTab(int index) {
    if (selectedTab == index) return;
    selectedTab = index;
    notifyListeners();
  }

  Future<void> scanDevices() async {
    errorMessage = null;
    try {
      if (!await _ensureBluetoothPermissions()) {
        errorMessage = '蓝牙权限未授权，无法扫描附近手表';
        notifyListeners();
        return;
      }
      if (deviceState == DeviceConnectionState.error) {
        deviceMachine.transition(DeviceConnectionState.disconnected);
      }
      deviceMachine.transition(DeviceConnectionState.scanning);
      scannedDevices = await _wearable.scanDevices();
      sdkStatus = 'Veepoo SDK 已加载';
      deviceMachine.transition(DeviceConnectionState.disconnected);
    } on WearableSdkNotConfigured catch (error) {
      sdkStatus = 'Veepoo SDK 未配置';
      errorMessage = error.message;
      deviceMachine.transition(DeviceConnectionState.error);
    } catch (_) {
      errorMessage = '扫描设备失败，请检查蓝牙和系统权限';
      deviceMachine.transition(DeviceConnectionState.error);
    }
    notifyListeners();
  }

  Future<bool> _ensureBluetoothPermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final android = await platform_info.DeviceInfoPlugin().androidInfo;
    final permissions = android.version.sdkInt >= 31
        ? [Permission.bluetoothScan, Permission.bluetoothConnect]
        : [Permission.locationWhenInUse];
    final statuses = await permissions.request();
    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> connectDevice(DeviceInfo device) async {
    errorMessage = null;
    try {
      if (deviceState == DeviceConnectionState.error) {
        deviceMachine.transition(DeviceConnectionState.disconnected);
      }
      deviceMachine.transition(DeviceConnectionState.connecting);
      await _wearable.connect(device.id);
      deviceMachine.transition(DeviceConnectionState.authenticating);
      capabilities = await _wearable.getCapabilities();
      deviceMachine.transition(DeviceConnectionState.syncing);
      final cursor = await _healthStore.readCursor();
      final records = await _wearable.syncHealthData(cursor: cursor);
      await _healthStore.upsert(records);
      connectedDevice = device;
      healthRecords = await _healthStore.recent();
      deviceMachine.transition(DeviceConnectionState.ready);
      syncStatus = records.isEmpty ? '设备暂无新数据' : '已同步 ${records.length} 条';
      unawaited(synchronizeCloud());
    } on WearableSdkNotConfigured catch (error) {
      sdkStatus = 'Veepoo SDK 未配置';
      errorMessage = error.message;
      deviceMachine.transition(DeviceConnectionState.error);
    } catch (_) {
      errorMessage = '连接失败，请靠近手表后重试';
      deviceMachine.transition(DeviceConnectionState.error);
    }
    notifyListeners();
  }

  Future<void> disconnectDevice() async {
    try {
      await _wearable.disconnect();
    } finally {
      connectedDevice = null;
      capabilities = null;
      if (deviceState != DeviceConnectionState.disconnected) {
        if (deviceState == DeviceConnectionState.error) {
          deviceMachine.transition(DeviceConnectionState.disconnected);
        } else {
          deviceMachine.transition(DeviceConnectionState.disconnected);
        }
      }
      notifyListeners();
    }
  }

  Future<void> startMeasurement(HealthMetric metric) async {
    if (connectedDevice == null) {
      errorMessage = '请先连接手表';
      notifyListeners();
      return;
    }
    if (!(capabilities?.supports(metric) ?? false)) {
      errorMessage = '当前设备不支持${metric.label}测量';
      notifyListeners();
      return;
    }
    try {
      deviceMachine.transition(DeviceConnectionState.measuring);
      await _wearable.startMeasurement(metric);
    } on WearableSdkNotConfigured catch (error) {
      errorMessage = error.message;
      deviceMachine.transition(DeviceConnectionState.error);
    }
    notifyListeners();
  }

  Future<void> stopMeasurement(HealthMetric metric) async {
    try {
      await _wearable.stopMeasurement(metric);
      if (deviceState == DeviceConnectionState.measuring) {
        deviceMachine.transition(DeviceConnectionState.ready);
      }
    } catch (_) {
      errorMessage = '停止测量失败';
    }
    notifyListeners();
  }

  Future<void> synchronizeCloud() async {
    if (_syncing) return;
    if (session == null) {
      syncStatus = '未登录，数据仅保存在本机';
      notifyListeners();
      return;
    }
    _syncing = true;
    try {
      final result = await _syncService.synchronizeNow();
      syncStatus =
          result.message ?? '已上传 ${result.uploaded} 条，拒绝 ${result.rejected} 条';
    } on ApiException catch (error) {
      syncStatus = '云端同步失败：${error.message}';
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> refreshCare() async {
    if (session == null) {
      careMembers = const [];
      return;
    }
    try {
      careMembers = await _api.getCareMembers();
    } on ApiException catch (error) {
      errorMessage = '关爱数据：${error.message}';
    }
    notifyListeners();
  }

  Future<bool> addCare(String mobile) => _guard(() async {
    await _api.addCare(mobile);
    careMembers = await _api.getCareMembers();
  });

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> _guard(Future<void> Function() operation) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await operation();
      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } catch (_) {
      errorMessage = '操作失败，请稍后重试';
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  void _handleWearableEvent(WearableEvent event) {
    if (event.type == 'healthRecord') {
      try {
        final record = HealthRecord.fromJson(event.payload);
        unawaited(_saveWearableRecord(record));
      } catch (_) {
        errorMessage = '收到无法识别的设备数据';
      }
    } else if (event.type == 'disconnected') {
      connectedDevice = null;
      if (deviceState != DeviceConnectionState.disconnected) {
        try {
          deviceMachine.transition(DeviceConnectionState.disconnected);
        } on StateError {
          // Native disconnects are authoritative; the next scan resets state.
        }
      }
    } else if (event.type == 'error') {
      errorMessage = '${event.payload['message'] ?? '设备通信异常'}';
    }
    notifyListeners();
  }

  Future<void> _saveWearableRecord(HealthRecord record) async {
    await _healthStore.upsert([record]);
    healthRecords = await _healthStore.recent();
    if (deviceState == DeviceConnectionState.measuring) {
      deviceMachine.transition(DeviceConnectionState.ready);
    }
    notifyListeners();
    unawaited(synchronizeCloud());
  }

  @override
  void dispose() {
    unawaited(_wearableEvents?.cancel());
    unawaited(_deviceStates?.cancel());
    unawaited(_connectivity?.cancel());
    deviceMachine.dispose();
    unawaited(_healthStore.close());
    super.dispose();
  }
}
