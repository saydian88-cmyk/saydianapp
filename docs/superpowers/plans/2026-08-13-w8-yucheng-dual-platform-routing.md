# W8 云创 SDK 双端自动路由 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 iOS 和 Android 自动将 W8、W8S、W8 Pro、W8 Ultra、W8 Ultra-R 的连接与设备交互路由到云创 SDK，同时保持其他设备的 Veepoo 行为不变。

**Architecture:** 保留 `WearableBridge` 的 Flutter 公共接口和既有 Veepoo 方法通道。新增 Dart 层 `RoutedWearableBridge`，它并行扫描 Veepoo 与云创、为设备添加不可冲突的来源前缀，并且将一次连接后的所有操作固定交给同一来源。云创适配器只调用官方 `yc_product_plugin` API；SDK 未报告支持的功能返回 `FEATURE_UNSUPPORTED`。

**Tech Stack:** Flutter 3.44.9、Dart 3.12.2、`yc_product_plugin`（固定提交 `ed5dabd0850edc5d64bb975c9a2f4d65c1344201`）、CocoaPods、Gradle、现有 Veepoo SDK。

## Global Constraints

- 原始交接压缩包及现有 Vendor 二进制只读，不删除、不覆盖。
- 不修改 `WearableBridge` 方法签名、Flutter 页面、后端 API、健康数据业务字段或产品需求。
- 仅精确识别 `W8`、`W8S`、`W8 Pro`、`W8 Ultra`、`W8 Ultra-R`；忽略大小写、空格、连字符样式，不能把 `W80` 或 `W8 Pro Max` 判为 W8。
- W8 只能由云创扫描记录发起连接；禁止 Veepoo 失败后再尝试云创的探测式连接。
- 云创连接后必须查询正式型号；验证失败或型号不在白名单时立即断开并返回 `YUCHENG_MODEL_MISMATCH`。
- iOS 与 Android 只允许一套共享的杰理依赖进入最终产物；禁止重复 framework 或重复 dex 类。
- 对云创不支持、无法读取或不能无损转换的数据，返回明确错误，不填充伪造值。
- 每一批代码仅暂存和提交本计划涉及文件，不能包含工作树里已有的无关修改。

---

## File Structure

- `lib/services/wearable_routing.dart`：设备来源枚举、W8 精确分类、带来源的设备标识和双 SDK 路由器。
- `lib/services/yucheng_product_client.dart`：对第三方 `YcProductPlugin` 的最薄封装，保存云创扫描对象并隔离第三方类型。
- `lib/services/yucheng_payload_mapper.dart`：纯 Dart 的云创健康、运动、能力、实时事件映射，不依赖 Flutter 通道。
- `lib/services/yucheng_wearable_bridge.dart`：将云创客户端实现为现有 `WearableBridge`。
- `lib/services/wearable_bootstrap.dart`：生产环境双 SDK 桥接组装点，允许测试注入两个来源。
- `lib/services/wearable_bridge.dart`：保留现有 Veepoo 方法通道，导出公共桥接类型；不把云创 API 写入页面层。
- `lib/services/app_controller.dart`：生产构造函数注入 `RoutedWearableBridge`。
- `pubspec.yaml`：固定云创插件的 Git 提交。
- `ios/Podfile`、`ios/Runner.xcodeproj/project.pbxproj`、`android/app/build.gradle.kts`：只在依赖检查确定的范围内消除重复链接。
- `test/wearable_routing_test.dart`：型号识别、去重、连接来源锁定和错误态。
- `test/yucheng_payload_mapper_test.dart`：SDK 数据转领域模型、枚举和异常映射。
- `test/yucheng_wearable_bridge_test.dart`：云创接口调用、型号二次校验、功能不支持和实时事件。
- `test/wearable_bootstrap_test.dart`：生产组装的 W8/非 W8 端到端桥接流程。
- `docs/device-feature-verification-20260812.md`：记录两端设备实测矩阵与恢复结果。
- `docs/HANDOFF-IOS-20260813.md`：补充 iOS 云创依赖与真机验证信息。

## Task 1: 建立纯 Dart 的 W8 设备来源模型

**Files:**
- Create: `lib/services/wearable_routing.dart`
- Create: `test/wearable_routing_test.dart`

**Interfaces:**
- Produces: `enum WearableTransport { veepoo, yucheng }`。
- Produces: `class W8DeviceClassifier { static bool matches(String name); }`。
- Produces: `class RoutedDevice`，包含 `DeviceInfo display`、`WearableTransport transport`、`String nativeIdentifier`。
- Produces: `RoutedDevice.scopedID(WearableTransport transport, String nativeIdentifier)`，返回 `veepoo:<id>` 或 `yucheng:<id>`。
- Produces: `RoutedDevice.fromScan(...)` 与 `RoutedDevice.fromDevice(WearableTransport transport, DeviceInfo device)`。

- [ ] **Step 1: 写 W8 名称和来源标识的失败测试**

```dart
test('matches only the five normalized W8 device names', () {
  expect(W8DeviceClassifier.matches('W8'), isTrue);
  expect(W8DeviceClassifier.matches('w8s'), isTrue);
  expect(W8DeviceClassifier.matches(' W8  Pro '), isTrue);
  expect(W8DeviceClassifier.matches('W8-Ultra'), isTrue);
  expect(W8DeviceClassifier.matches('w8 ultra-r'), isTrue);
  expect(W8DeviceClassifier.matches('W80'), isFalse);
  expect(W8DeviceClassifier.matches('W8 Pro Max'), isFalse);
});

test('scopes IDs without losing the vendor identifier', () {
  final routed = RoutedDevice.fromScan(
    transport: WearableTransport.yucheng,
    nativeIdentifier: 'A1-B2',
    name: 'W8 Ultra',
  );

  expect(routed.display.id, 'yucheng:A1-B2');
  expect(routed.nativeIdentifier, 'A1-B2');
  expect(routed.transport, WearableTransport.yucheng);
});
```

- [ ] **Step 2: 运行测试并确认类型尚不存在**

Run: `flutter test --no-pub test/wearable_routing_test.dart`

Expected: FAIL，包含 `W8DeviceClassifier` 或 `RoutedDevice` 未定义。

- [ ] **Step 3: 实现最小名称归一化和设备模型**

```dart
enum WearableTransport { veepoo, yucheng }

class W8DeviceClassifier {
  static const _models = {'W8', 'W8S', 'W8PRO', 'W8ULTRA', 'W8ULTRAR'};

  static bool matches(String name) {
    final normalized = name
        .toUpperCase()
        .replaceAll(RegExp(r'[\s\-‐‑‒–—]'), '');
    return _models.contains(normalized);
  }
}
```

`RoutedDevice.fromScan` 必须在 `DeviceInfo.id` 写入来源前缀，并将 SDK 返回的名称、型号、固件和 RSSI 原样放入 `display`。

- [ ] **Step 4: 运行路由单测并确认通过**

Run: `flutter test --no-pub test/wearable_routing_test.dart`

Expected: PASS，0 failures。

- [ ] **Step 5: 提交纯路由模型**

```bash
git add lib/services/wearable_routing.dart test/wearable_routing_test.dart
git commit -m "feat: classify W8 devices by SDK transport"
```

## Task 2: 实现双来源扫描、去重和连接锁定

**Files:**
- Modify: `lib/services/wearable_routing.dart`
- Modify: `test/wearable_routing_test.dart`

**Interfaces:**
- Consumes: 两个 `WearableBridge` 实例、`RoutedDevice` 和 `W8DeviceClassifier`。
- Produces: `class RoutedWearableBridge implements WearableBridge`。
- Produces: `activeTransport`，仅在连接成功后设置；`disconnect()` 完成后清空。
- Produces: `FlutterError(code: 'YUCHENG_DISCOVERY_MISMATCH', ...)`，用于旧来源单独发现 W8 的场景。

- [ ] **Step 1: 写并行扫描、优先级和来源锁定的失败测试**

```dart
test('prefers Yucheng for a W8 seen by both SDKs', () async {
  final veepoo = _FakeWearableBridge(scanned: [
    const DeviceInfo(id: 'AA:01', name: 'W8 Ultra'),
    const DeviceInfo(id: 'AA:02', name: 'VP-100'),
  ]);
  final yucheng = _FakeWearableBridge(scanned: [
    const DeviceInfo(id: 'AA:01', name: 'W8 Ultra'),
  ]);
  final bridge = RoutedWearableBridge(veepoo: veepoo, yucheng: yucheng);

  final devices = await bridge.scanDevices();

  expect(devices.map((item) => item.id), contains('yucheng:AA:01'));
  expect(devices.map((item) => item.id), isNot(contains('veepoo:AA:01')));
  expect(devices.map((item) => item.id), contains('veepoo:AA:02'));
});

test('locks every later operation to the transport that connected', () async {
  final veepoo = _FakeWearableBridge(scanned: const []);
  final yucheng = _FakeWearableBridge(scanned: [
    const DeviceInfo(id: 'YC-1', name: 'W8S'),
  ]);
  final bridge = RoutedWearableBridge(veepoo: veepoo, yucheng: yucheng);

  await bridge.scanDevices();
  await bridge.connect(
    'yucheng:YC-1',
    profile: const WearableUserProfile(gender: 1, heightCm: 170, weightKg: 65, age: 30, birthYear: 1996, targetSteps: 8000),
  );
  await bridge.startMeasurement(HealthMetric.heartRate);

  expect(yucheng.connectCalls, ['YC-1']);
  expect(yucheng.measurementCalls, [HealthMetric.heartRate]);
  expect(veepoo.connectCalls, isEmpty);
  expect(veepoo.measurementCalls, isEmpty);
});
```

`_FakeWearableBridge` 必须在本测试文件内实现所有 `WearableBridge` 非空返回方法；未测试命令返回空列表、空 map 或完成的 `Future<void>`，避免测试依赖平台通道。

- [ ] **Step 2: 运行测试并确认路由器尚不存在**

Run: `flutter test --no-pub test/wearable_routing_test.dart`

Expected: FAIL，包含 `RoutedWearableBridge` 未定义。

- [ ] **Step 3: 实现扫描合并和单来源命令转发**

`scanDevices()` 同时等待两套扫描结果，按原生标识去重：

```dart
final results = await Future.wait([veepoo.scanDevices(), yucheng.scanDevices()]);
final candidates = <RoutedDevice>[
  ...results[0].map((device) => RoutedDevice.fromDevice(WearableTransport.veepoo, device)),
  ...results[1].map((device) => RoutedDevice.fromDevice(WearableTransport.yucheng, device)),
];
```

对同一原始标识的候选项，名称满足 `W8DeviceClassifier.matches` 时选择云创；其他名称选择 Veepoo。
`connect` 只能从本次扫描记录中解析展示 ID；未找到时返回 `UNKNOWN_SCANNED_DEVICE`。
若记录是 Veepoo 来源但名称为 W8，返回 `YUCHENG_DISCOVERY_MISMATCH`，不调用任何 SDK 的 `connect`。

每一个 `WearableBridge` 方法均通过 `activeBridge` 转发；未连接时返回 `FlutterError(code: 'NOT_CONNECTED', ...)`。
`events` 必须将扫描事件改写为来源前缀 ID，且只转发当前连接来源的非扫描事件。

- [ ] **Step 4: 运行路由测试和原桥接测试**

Run: `flutter test --no-pub test/wearable_routing_test.dart test/wearable_bridge_test.dart`

Expected: PASS，0 failures。

- [ ] **Step 5: 提交双来源路由器**

```bash
git add lib/services/wearable_routing.dart test/wearable_routing_test.dart
git commit -m "feat: route W8 connections through Yucheng"
```

## Task 3: 固定云创插件并建立原生依赖冲突门槛

**Files:**
- Modify: `pubspec.yaml`
- Modify: `ios/Podfile`
- Modify: `android/app/build.gradle.kts`
- Modify: `ios/Runner/Vendor/README.md`
- Modify: `android/app/libs/README.md`

**Interfaces:**
- Consumes: 云创官方 `yc_product_plugin` 提交 `ed5dabd0850edc5d64bb975c9a2f4d65c1344201`。
- Produces: 可复现的 Flutter、CocoaPods 和 Gradle 解析结果，且最终 iOS/Android 没有同名杰理二进制重复进入应用。

- [ ] **Step 1: 添加固定 Git 依赖并先让依赖解析失败或成功有证据**

在 `pubspec.yaml` 的 `dependencies` 添加：

```yaml
  yc_product_plugin:
    git:
      url: https://gitee.com/yucheng_3/yc_product_plugin.git
      path: code
      ref: ed5dabd0850edc5d64bb975c9a2f4d65c1344201
```

Run: `flutter pub get`

Expected: 成功写入锁定提交；如果 Git 不可访问，命令必须明确显示网络或仓库错误，不能改用未固定的 `master`。

- [ ] **Step 2: 收集 iOS 和 Android 重复依赖的基线**

Run:

```bash
pod install --project-directory=ios
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphoneos -destination 'generic/platform=iOS' build
./gradlew :app:dependencies --configuration debugRuntimeClasspath
./gradlew :app:assembleDebug
```

Expected: 记录第一个失败点或两端成功构建的输出。使用 `rg 'JL_BLEKit|JLDialUnit|ZipZap|jl_rcsp|JL_Watch'` 检查输出，列出每个重复模块的来源和版本。

- [ ] **Step 3: 仅保留单套共享杰理组件**

对 iOS，云创 Pod 的 `JL_BLEKit.xcframework`、`JLDialUnit.xcframework` 或同名 framework 与 Runner 直链的同名库只能保留一方；修改 `project.pbxproj` 的 `PBXFrameworksBuildPhase`、`Embed Frameworks` 和 `Vendor` group，使最终产物没有同名重复嵌入。

对 Android，在 `android/app/build.gradle.kts` 中把既有 `jl_bt_ota_V1.10.0_10931-release.aar`、`jl_rcsp_V0.7.2_527-release.aar`、`JL_Watch_V1.13.1_11214-release.aar` 与云创插件声明的同类库统一为一套经 `assembleDebug` 验证的版本；`vpprotocol-2.3.77.15.aar` 与 `vpbluetooth-1.20.aar` 保持原文件和引用不变。

将最终选择、SHA-256、删除的 Xcode 链接项和 Gradle 依赖树结果写入两个 README；不得删除 Vendor 或 `android/app/libs` 中的原始文件。

- [ ] **Step 4: 重新运行两端构建并确认无重复类/重复 framework**

Run:

```bash
flutter build ios --debug --no-pub
flutter build apk --debug --no-pub
```

Expected: 两端构建成功；iOS 构建日志不含 `Multiple commands produce` 或重复 framework 名，Android 日志不含 `Duplicate class`。

- [ ] **Step 5: 提交锁定依赖和依赖证据**

```bash
git add pubspec.yaml pubspec.lock ios/Podfile ios/Podfile.lock ios/Runner.xcodeproj/project.pbxproj ios/Runner/Vendor/README.md android/app/build.gradle.kts android/app/libs/README.md
git commit -m "build: lock Yucheng SDK dependencies"
```

## Task 4: 构建可测试的云创客户端与数据映射器

**Files:**
- Create: `lib/services/yucheng_product_client.dart`
- Create: `lib/services/yucheng_payload_mapper.dart`
- Create: `test/yucheng_payload_mapper_test.dart`

**Interfaces:**
- Produces: `abstract interface class YuchengProductClient`，以 Dart 基础类型暴露扫描、连接、设备信息、能力、健康历史、测量、运动、设置和事件流。
- Produces: `class PluginYuchengProductClient implements YuchengProductClient`，唯一直接 import `package:yc_product_plugin/yc_product_plugin.dart` 的文件。
- Produces: `YuchengPayloadMapper.healthRecords(...)`、`sportRecords(...)`、`capabilities(...)`、`event(...)`。
- Produces: `class YuchengOperationResult<T> { const YuchengOperationResult(this.status, this.data); final int status; final T? data; }`，状态 `0`、`1`、`2` 分别表示成功、失败和设备不支持。
- Produces: 本地 `YuchengMeasurementType` 与 `YuchengSportState` 常量，第三方枚举只在 `PluginYuchengProductClient` 内部转换。

- [ ] **Step 1: 写健康、运动和能力映射的失败测试**

```dart
test('maps official Yucheng step, heart and pressure rows without inventing values', () {
  final records = YuchengPayloadMapper.healthRecords(
    deviceId: 'yucheng:AA:01',
    firmwareVersion: '1.2.3',
    rowsByType: {
      YuchengHealthDataType.step: [
        {'startTimeStamp': 1786579200, 'step': 4567, 'distance': 3210, 'calories': 198},
      ],
      YuchengHealthDataType.heartRate: [
        {'startTimeStamp': 1786579260, 'heartRate': 72},
      ],
      YuchengHealthDataType.bloodPressure: [
        {'startTimeStamp': 1786579320, 'systolicBloodPressure': 118, 'diastolicBloodPressure': 76},
      ],
    },
  );

  expect(records.where((item) => item.metric == HealthMetric.steps).single.values['value'], 4567);
  expect(records.where((item) => item.metric == HealthMetric.distance).single.values['value'], 3.21);
  expect(records.where((item) => item.metric == HealthMetric.heartRate).single.values['value'], 72);
  expect(records.where((item) => item.metric == HealthMetric.bloodPressure).single.values, {
    'systolic': 118,
    'diastolic': 76,
  });
});

test('maps W8 feature flags only when the SDK reports support', () {
  final capabilities = YuchengPayloadMapper.capabilities({
    'isSupportHeartRate': true,
    'isSupportBloodOxygen': true,
    'isSupportFindDevice': true,
    'isSupportOta': true,
    'alarmClockCount': 0,
  });

  expect(capabilities.supports(HealthMetric.heartRate), isTrue);
  expect(capabilities.supports(HealthMetric.bloodOxygen), isTrue);
  expect(capabilities.supportsFeature(DeviceFeature.findWatch), isTrue);
  expect(capabilities.supportsFeature(DeviceFeature.alarms), isFalse);
});
```

- [ ] **Step 2: 运行映射测试并确认类型尚不存在**

Run: `flutter test --no-pub test/yucheng_payload_mapper_test.dart`

Expected: FAIL，包含 `YuchengPayloadMapper` 未定义。

- [ ] **Step 3: 实现客户端边界和纯映射**

客户端将官方常量隔离为本地整数：

```dart
abstract final class YuchengHealthDataType {
  static const step = 0;
  static const sleep = 1;
  static const heartRate = 2;
  static const bloodPressure = 3;
  static const combined = 4;
  static const invasive = 5;
  static const sportHistory = 6;
}

abstract final class YuchengMeasurementType {
  static const heartRate = 0;
  static const bloodPressure = 1;
  static const bloodOxygen = 2;
  static const bodyTemperature = 4;
}

abstract final class YuchengSportState {
  static const stop = 0;
  static const start = 1;
}
```

`healthRecords` 仅在行内存在有效时间戳和对应数值时生成记录；距离从米转换为 km，卡路里保持 SDK 的 kcal 数值。组合数据拆成血氧、体温、血糖和 HRV 的独立记录；字段缺失的指标不生成记录。

`sportRecords` 将云创 `run`、`outdoorWalking`、`riding`、`onfoot` 映射为现有 `running`、`walking`、`cycling`、`hiking`，距离从米转换为 km。

- [ ] **Step 4: 运行映射单测并确认通过**

Run: `flutter test --no-pub test/yucheng_payload_mapper_test.dart`

Expected: PASS，0 failures。

- [ ] **Step 5: 提交云创客户端和映射器**

```bash
git add lib/services/yucheng_product_client.dart lib/services/yucheng_payload_mapper.dart test/yucheng_payload_mapper_test.dart
git commit -m "feat: map Yucheng wearable data"
```

## Task 5: 以云创接口实现完整的 WearableBridge

**Files:**
- Create: `lib/services/yucheng_wearable_bridge.dart`
- Create: `test/yucheng_wearable_bridge_test.dart`

**Interfaces:**
- Consumes: `YuchengProductClient`、`YuchengPayloadMapper`、`WearableUserProfile`。
- Produces: `class YuchengWearableBridge implements WearableBridge`。
- Produces: `FlutterError(code: 'YUCHENG_MODEL_MISMATCH', ...)`、`FlutterError(code: 'FEATURE_UNSUPPORTED', ...)` 和 `FlutterError(code: 'YUCHENG_OPERATION_FAILED', ...)`。

- [ ] **Step 1: 写连接后型号校验和交互来源的失败测试**

```dart
test('disconnects when the connected Yucheng model is not in the W8 allowlist', () async {
  final client = _FakeYuchengClient(model: 'YC Ring');
  final bridge = YuchengWearableBridge(client: client);

  await expectLater(
    bridge.connect(
      'YC-01',
      profile: const WearableUserProfile(gender: 2, heightCm: 160, weightKg: 50, age: 28, birthYear: 1998, targetSteps: 9000),
    ),
    throwsA(isA<PlatformException>().having((error) => error.code, 'code', 'YUCHENG_MODEL_MISMATCH')),
  );
  expect(client.disconnectCount, 1);
});

test('maps unavailable Yucheng operations to FEATURE_UNSUPPORTED', () async {
  final client = _FakeYuchengClient(model: 'W8 Ultra', measurementStatus: 2);
  final bridge = YuchengWearableBridge(client: client);
  await bridge.connect(
    'YC-01',
    profile: const WearableUserProfile(gender: 1, heightCm: 175, weightKg: 70, age: 30, birthYear: 1996, targetSteps: 10000),
  );

  await expectLater(
    bridge.startMeasurement(HealthMetric.bloodGlucose),
    throwsA(isA<PlatformException>().having((error) => error.code, 'code', 'FEATURE_UNSUPPORTED')),
  );
});
```

- [ ] **Step 2: 运行云创桥接测试并确认实现不存在**

Run: `flutter test --no-pub test/yucheng_wearable_bridge_test.dart`

Expected: FAIL，包含 `YuchengWearableBridge` 未定义。

- [ ] **Step 3: 实现初始化、扫描、连接、状态和健康交互**

`YuchengWearableBridge` 在首次操作前调用一次 `client.initialize(reconnectEnabled: true, logEnabled: false)`。
扫描将云创 `deviceIdentifier` 作为原始 ID；连接后按顺序执行：连接、查询型号、查询固件、查询能力、同步手机时间、写入用户资料和步数目标。

测量映射必须为：

```dart
const measurementTypes = {
  HealthMetric.heartRate: YuchengMeasurementType.heartRate,
  HealthMetric.bloodPressure: YuchengMeasurementType.bloodPressure,
  HealthMetric.bloodOxygen: YuchengMeasurementType.bloodOxygen,
  HealthMetric.bodyTemperature: YuchengMeasurementType.bodyTemperature,
};
```

`startMeasurement` 和 `stopMeasurement` 对没有映射的指标直接返回 `FEATURE_UNSUPPORTED`。
`syncHealthData` 查询步骤、睡眠、心率、血压、组合与运动历史类型，再用 `YuchengPayloadMapper` 生成领域记录。

运动映射必须为：`running -> outdoorRunning`、`walking -> outdoorWalking`、`cycling -> riding`、`hiking -> onfoot`；停止调用客户端的 `YuchengSportState.stop`。

- [ ] **Step 4: 实现设置、设备功能和事件映射**

对每项 `WearableBridge` 方法只调用对应云创 API：

- 自动测量和心率预警：健康监测与心率告警 API；云创无读取接口时 `readAutoMeasureSettings`、`readHeartRateWarning` 返回 `FEATURE_UNSUPPORTED`。
- 查找、相机、天气、通知、联系人、闹钟、表盘、屏幕：先查询 `DeviceFeature`，再调用官方相应控制、设置或表盘 API。
- `readDeviceFeature` 无官方读取接口时返回 `FEATURE_UNSUPPORTED`，不能返回缓存伪装为设备状态。
- 云创事件转换为现有 `WearableEvent`：蓝牙状态、`deviceRealHeartRate`、`deviceRealBloodPressure`、`deviceRealBloodOxygen`、`deviceRealTemperature`、运动状态、相机快门和表盘进度。

所有非成功插件状态通过一个 `requireSuccess` 帮助方法转换：状态 `2` 返回 `FEATURE_UNSUPPORTED`，状态 `1` 返回 `YUCHENG_OPERATION_FAILED`。

- [ ] **Step 5: 运行云创桥接测试**

Run: `flutter test --no-pub test/yucheng_wearable_bridge_test.dart test/yucheng_payload_mapper_test.dart`

Expected: PASS，0 failures。

- [ ] **Step 6: 提交云创桥接实现**

```bash
git add lib/services/yucheng_wearable_bridge.dart test/yucheng_wearable_bridge_test.dart
git commit -m "feat: add Yucheng wearable bridge"
```

## Task 6: 接入生产控制器并验证 W8 与 Veepoo 共存

**Files:**
- Modify: `lib/services/app_controller.dart`
- Create: `lib/services/wearable_bootstrap.dart`
- Create: `test/wearable_bootstrap_test.dart`
- Modify: `test/qa_user_flows_test.dart`

**Interfaces:**
- Consumes: `RoutedWearableBridge(veepoo: MethodChannelWearableBridge(), yucheng: YuchengWearableBridge())`。
- Produces: `WearableBridge createProductionWearableBridge({WearableBridge? veepoo, WearableBridge? yucheng})` 和 `AppController.production()` 的双 SDK 行为。

- [ ] **Step 1: 写控制器 W8 与非 W8 流程的失败测试**

```dart
test('production bridge connects W8 through Yucheng while a VP watch remains on Veepoo', () async {
  final veepoo = _FakeWearableBridge(scanned: const [
    DeviceInfo(id: 'VP-01', name: 'VP-100'),
  ]);
  final yucheng = _FakeWearableBridge(scanned: const [
    DeviceInfo(id: 'YC-01', name: 'W8 Pro'),
  ]);
  final bridge = createProductionWearableBridge(
    veepoo: veepoo,
    yucheng: yucheng,
  );
  final w8 = (await bridge.scanDevices()).singleWhere((device) => device.name == 'W8 Pro');
  await bridge.connect(w8.id, profile: _profile);

  expect(yucheng.connectCalls, ['YC-01']);
  expect(veepoo.connectCalls, isEmpty);
});

const _profile = WearableUserProfile(
  gender: 1,
  heightCm: 175,
  weightKg: 70,
  birthYear: 1996,
  age: 30,
  targetSteps: 10000,
);
```

- [ ] **Step 2: 运行控制器测试并确认生产构造函数尚未使用路由器**

Run: `flutter test --no-pub test/wearable_bootstrap_test.dart`

Expected: FAIL，包含 `createProductionWearableBridge` 未定义。

- [ ] **Step 3: 在生产构造函数装配双 SDK**

```dart
WearableBridge createProductionWearableBridge({
  WearableBridge? veepoo,
  WearableBridge? yucheng,
}) => RoutedWearableBridge(
  veepoo: veepoo ?? MethodChannelWearableBridge(),
  yucheng: yucheng ?? YuchengWearableBridge(),
);
```

保持现有权限申请、状态机、后端同步和页面文字不变。
更新已有 QA 假桥接中设备 ID 的断言，使其接受带 `veepoo:` 前缀的展示 ID，但只向原生 Veepoo 传递未加前缀的地址。

- [ ] **Step 4: 运行控制器与既有设备流程测试**

Run:

```bash
flutter test --no-pub test/wearable_bootstrap_test.dart test/qa_user_flows_test.dart test/prototype_coverage_test.dart
```

Expected: PASS，0 failures；Veepoo 测试连接仍使用原始测试设备。

- [ ] **Step 5: 提交生产装配**

```bash
git add lib/services/wearable_bootstrap.dart lib/services/app_controller.dart test/wearable_bootstrap_test.dart test/qa_user_flows_test.dart
git commit -m "feat: enable W8 SDK routing in production"
```

## Task 7: 双端构建、真机回归与交接记录

**Files:**
- Modify: `docs/device-feature-verification-20260812.md`
- Modify: `docs/HANDOFF-IOS-20260813.md`

**Interfaces:**
- Consumes: 已锁定的 SDK、W8 真机、既有 Veepoo 真机。
- Produces: iOS 和 Android 的构建证据、按设备/SDK 分开的功能验证与恢复记录。

- [ ] **Step 1: 运行静态分析和全量 Dart 测试**

Run:

```bash
flutter analyze --no-pub
flutter test --no-pub
git diff --check
```

Expected: 三条命令成功；不包含 analyzer error、测试失败或空白差异问题。

- [ ] **Step 2: 构建两个原生调试包**

Run:

```bash
flutter build ios --debug --no-pub
flutter build apk --debug --no-pub
```

Expected: 两端命令成功。若任一命令因重复类、重复 framework 或第三方二进制 ABI 不兼容失败，保留旧 SDK 文件、记录完整错误，并停止对该平台的二进制替换。

- [ ] **Step 3: 在 iPhone、Android 和两类设备上执行回归**

每个平台依次连接一台 W8 与一台现有 Veepoo 手表，记录下列结果：扫描名称、展示 ID 前缀、实际 SDK、连接后型号、能力清单、历史同步、一次心率测量、断开与重新扫描。

对支持的闹钟、通知、相机、查找、表盘、天气和屏幕设置，先读取可读取设置，写入带“赛电测试”标识的临时项，读取确认后删除临时项或恢复初始值。

- [ ] **Step 4: 更新交接文档**

在 `docs/device-feature-verification-20260812.md` 追加四行设备矩阵：`iOS/W8`、`Android/W8`、`iOS/Veepoo`、`Android/Veepoo`。
每行必须包含日期、设备名称、SDK 来源、构建号、扫描/连接/同步/断开结果、写入恢复结果、未支持功能和原始错误码。

在 `docs/HANDOFF-IOS-20260813.md` 记录云创固定提交、CocoaPods 依赖、最终共享杰理组件来源、重新构建命令和 iPhone W8 回归结果。

- [ ] **Step 5: 提交验证记录**

```bash
git add docs/device-feature-verification-20260812.md docs/HANDOFF-IOS-20260813.md
git commit -m "docs: record W8 dual SDK verification"
```

## Plan Self-Review

### Spec coverage

- W8 五型号精确识别：Task 1。
- 双 SDK 自动选择、扫描去重与单来源交互：Task 2。
- 云创官方 SDK 固定与 iOS/Android 依赖冲突：Task 3。
- 云创健康、运动、能力和事件数据映射：Task 4 与 Task 5。
- 页面不改、既有 Veepoo 不回归：Task 6。
- 双端构建、四个真机组合和恢复记录：Task 7。

### Placeholder scan

计划的所有任务均给出文件、接口、输入代码、命令和成功准则。

### Type consistency

所有路由层使用 `WearableTransport`、`RoutedDevice` 和既有 `WearableBridge`；云创第三方类型只在 `PluginYuchengProductClient` 中出现，映射器和路由器只处理领域模型或基础类型。
