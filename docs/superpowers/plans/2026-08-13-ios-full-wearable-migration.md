# iOS Full Wearable Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 Android 已实现的赛电手表能力完整移植到 iOS，并用自动化测试、构建和真机回归证明结果。

**Architecture:** 保留 Flutter MethodChannel 协议和现有 `VeepooWearableAdapter`，新增纯 Swift 映射器供单元测试。所有 SDK 调用执行连接/能力校验、单次完成保护和超时，最终只把已实现能力写入 `integratedFeatures`。

**Tech Stack:** Flutter 3.44.9、Dart 3.12.2、Swift、Xcode 26.6、VeepooBleSDK、XCTest、Flutter Test。

## Global Constraints

- 原始压缩包和交接素材只读。
- 不修改 Flutter 公共方法名、wire name、后端协议或业务逻辑。
- 不伪造后端、SDK 授权、设备固件或正式签名能力。
- 真机写入前保存快照，测试后恢复。
- 每项缺陷先保留复现与根因证据，再写回归测试和修复。
- 在 `codex/ios-full-migration` 分支执行，不混入无关改动。

---

### Task 1: 固化基线与原生映射器

**Files:**
- Create: `ios/Runner/WearablePayloadMapper.swift`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Modify: `ios/RunnerTests/RunnerTests.swift`

**Interfaces:**
- Consumes: Flutter 的 `SportMode.wireName`、`DeviceFeature.wireName` 和 Android payload 字段。
- Produces: `WearablePayloadMapper.sportMode(_:)`、`clampedHeartWarning(_:)`、`minutes(hour:minute:)`、`bool(_:default:)`。

- [ ] **Step 1: 写映射器失败测试**

```swift
func testSportModeMappingAndHeartWarningClamp() {
  XCTAssertEqual(WearablePayloadMapper.sportMode("walking"), .outdoorWalk)
  XCTAssertEqual(WearablePayloadMapper.sportMode("cycling"), .outdoorRide)
  XCTAssertEqual(WearablePayloadMapper.clampedHeartWarning(40), 70)
  XCTAssertEqual(WearablePayloadMapper.clampedHeartWarning(240), 190)
}
```

- [ ] **Step 2: 运行并确认因类型不存在而失败**

Run: `xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=赛电 iOS 调试' -only-testing:RunnerTests`

Expected: FAIL，提示 `WearablePayloadMapper` 不存在。

- [ ] **Step 3: 实现最小映射器并加入 Runner/RunnerTests 编译源**

```swift
enum WearablePayloadMapper {
  static func clampedHeartWarning(_ value: Int) -> Int { min(190, max(70, value)) }
  static func minutes(hour: Int, minute: Int) -> Int { hour * 60 + minute }
  static func bool(_ value: Any?, default fallback: Bool = false) -> Bool {
    value as? Bool ?? fallback
  }
}
```

- [ ] **Step 4: 运行 XCTest 并确认通过**

Run: Task 1 Step 2 的 `xcodebuild test` 命令。

Expected: PASS，0 failures。

### Task 2: 修复添加关爱输入框生命周期

**Files:**
- Modify: `lib/ui/pages.dart`
- Modify: `test/ui_shell_test.dart`

**Interfaces:**
- Consumes: `_showAddCareDialog(BuildContext, AppController)`。
- Produces: `_AddCareDialog`，由组件自身拥有并释放 `TextEditingController`。

- [ ] **Step 1: 写关闭弹窗后继续 pump 的失败测试**

```dart
testWidgets('closing add care dialog does not use a disposed controller', (tester) async {
  await tester.tap(find.text('添加关爱'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('取消'));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: 运行测试并确认复现 disposed controller**

Run: `flutter test --no-pub test/ui_shell_test.dart --plain-name 'closing add care dialog does not use a disposed controller'`

Expected: FAIL，包含 `TextEditingController was used after being disposed`。

- [ ] **Step 3: 把弹窗内容改为 StatefulWidget 自持控制器**

```dart
class _AddCareDialogState extends State<_AddCareDialog> {
  final mobileController = TextEditingController();
  @override
  void dispose() {
    mobileController.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 4: 运行单测和全量 Flutter 测试**

Run: `flutter test --no-pub test/ui_shell_test.dart`

Run: `flutter test --no-pub`

Expected: PASS，0 failures。

### Task 3: 定位并修复 iOS 重复类链接

**Files:**
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Modify: `ios/Runner/Vendor/README.md`

**Interfaces:**
- Consumes: 目标设备启动日志、`nm` 符号和官方 Demo 的 framework 依赖布局。
- Produces: 唯一的 `JL_Tools`、`JL_Timer`、`JLModel_File` 类来源。

- [ ] **Step 1: 收集每个 framework 的类符号与动态依赖**

Run: `nm -U ios/Runner/Vendor/JLDialUnit.framework/JLDialUnit | rg 'OBJC_CLASS_\$_(JL_Tools|JL_Timer|JLModel_File)'`

Run: `nm -U ios/Runner/Vendor/JL_BLEKit.framework/JL_BLEKit | rg 'OBJC_CLASS_\$_(JL_Tools|JL_Timer|JLModel_File)'`

Run: `otool -L ios/Runner/Vendor/VeepooBleSDK.framework/VeepooBleSDK`

Expected: 明确哪个静态库把同名类复制进 Runner。

- [ ] **Step 2: 与官方 Demo 的 Link/Embed 关系逐项比较**

Run: `rg -n 'JLDialUnit|JL_BLEKit' /tmp/saidian-hband-ios-sdk-ref-20260813/iOS_sdk_source/Demo/VeepooBleSDKDemo/VeepooBleSDKDemo.xcodeproj/project.pbxproj`

Expected: 得到官方推荐的唯一链接组合。

- [ ] **Step 3: 只移除重复链接项，保留运行所需嵌入项**

Implementation: 修改 `PBXFrameworksBuildPhase` 或 `Embed Frameworks` 中确认重复的一项，不删除磁盘上的交付 framework。

- [ ] **Step 4: 真机冷启动并检查告警**

Run: `flutter run --no-pub -d 00008130-001C098C2290001C`

Expected: 启动日志不出现三项重复类告警，且设备连接入口可用。

### Task 4: 运动、自动测量和心率预警

**Files:**
- Modify: `ios/Runner/AppDelegate.swift`
- Modify: `ios/RunnerTests/RunnerTests.swift`
- Modify: `test/qa_user_flows_test.dart`

**Interfaces:**
- Produces: `startSport`、`stopSport`、`readSportRecords`、`readAutoMeasureSettings`、`setAutoMeasureSetting`、`readHeartRateWarning`、`setHeartRateWarning` 的 iOS 实现。
- Events: `sportState`、`sportSyncProgress`。

- [ ] **Step 1: 写运动模式、设置范围和返回 payload 的失败测试**

```swift
XCTAssertEqual(WearablePayloadMapper.sportWireName(rawValue: 4), "walking")
XCTAssertEqual(WearablePayloadMapper.clampedHeartWarning(191), 190)
```

- [ ] **Step 2: 运行 XCTest 并确认新断言失败**

Run: Task 1 的 `xcodebuild test` 命令。

- [ ] **Step 3: 按官方 API 接入设备运动、历史运动、自动检测和心率警报**

Implementation calls:

```swift
manager.peripheralManage.veepooSDKSettingDeviceRunning(settingType, runMode: mode, result: callback)
manager.peripheralManage.veepooSDKStartReadDeviceRunningData(callback)
manager.peripheralManage.veepooSDKReadAutoMonitSwitchInfo(callback)
manager.peripheralManage.veepooSDKSetAutoMonitSwitch(with: model, result: callback)
manager.peripheralManage.veepooSDKSettingDeviceHeartAlarm(with: model, settingMode: mode, successResult: success, failureResult: failure)
```

- [ ] **Step 4: 运行 XCTest、Flutter 测试和真机专项回归**

Expected: 四种运动模式可开始/停止；历史记录字段可解析；支持的自动检测可读写；心率值限制在 70–190。

### Task 5: 基础设备功能

**Files:**
- Modify: `ios/Runner/AppDelegate.swift`
- Modify: `ios/RunnerTests/RunnerTests.swift`
- Modify: `test/prototype_coverage_test.dart`

**Interfaces:**
- Produces: `find_watch`、`camera`、`notifications`、`alarms`、`contacts`、`phone_calls` 的 read/write/action。
- Events: `cameraShutter`、`deviceFeatureChanged`。

- [ ] **Step 1: 写通知键、闹钟重复日和联系人 payload 的失败测试**

```swift
XCTAssertEqual(WearablePayloadMapper.repeatMask(days: [1, 3, 5]), 0b00101010)
XCTAssertEqual(WearablePayloadMapper.safeLabel("测试联系人", limit: 20), "测试联系人")
```

- [ ] **Step 2: 运行 XCTest 并确认失败**

- [ ] **Step 3: 用 SDK 的查找、相机、消息、闹钟和联系人接口实现读写**

Implementation calls:

```swift
veepooSDK_searchDeviceFuntion(withState:result:)
veepooSDKSettingCameraType(_:settingAndMonitorResult:)
veepooSDKSettingMessageType(_:settingState:complete:)
veepooSDKSettingDeviceAlarm(...)
veepooSDKSettingDeviceContacts(withOpCode:opModel:...)
```

- [ ] **Step 4: 真机创建测试项、读取验证、删除并恢复**

Expected: 测试联系人/闹钟不残留；关闭相机模式后设备退出遥控状态。

### Task 6: 天气、世界时钟、提醒、评估和屏幕

**Files:**
- Modify: `ios/Runner/AppDelegate.swift`
- Modify: `ios/RunnerTests/RunnerTests.swift`
- Modify: `lib/services/device_weather_service.dart`
- Modify: `test/prototype_coverage_test.dart`

**Interfaces:**
- Produces: `weather`、`world_clock`、`health_reminders`、`health_assessment`、`screen_display`。
- Local config: QWeather key only from ignored/local handoff configuration.

- [ ] **Step 1: 写分钟数、UTC 偏移、亮度和持续时间边界测试**

```swift
XCTAssertEqual(WearablePayloadMapper.minutes(hour: 23, minute: 59), 1439)
XCTAssertEqual(WearablePayloadMapper.clamp(9, minimum: 1, maximum: 5), 5)
```

- [ ] **Step 2: 运行 XCTest 并确认边界测试失败**

- [ ] **Step 3: 对接对应 SDK 读写接口并保持 Android payload 字段一致**

Implementation calls include world clock, long-seat/health reminder, health assessment, brightness, screen duration and raise-to-wake APIs declared in `VPPeripheralBaseManage.h`.

- [ ] **Step 4: 真机读取快照、写入测试值、读取校验并恢复**

Expected: 所有支持项读写闭环；不支持项返回 `FEATURE_UNSUPPORTED`。

### Task 7: 系统表盘与照片表盘

**Files:**
- Modify: `ios/Runner/AppDelegate.swift`
- Modify: `ios/RunnerTests/RunnerTests.swift`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Modify: `ios/Runner/Info.plist`

**Interfaces:**
- Produces: `watch_faces`、`photo_watch_face` 的列表、当前项、切换、传输进度。
- Events: `deviceFeatureProgress`。

- [ ] **Step 1: 写表盘输入校验和进度归一化失败测试**

```swift
XCTAssertEqual(WearablePayloadMapper.progress(completed: 5, total: 20), 25)
XCTAssertNil(WearablePayloadMapper.localFileURL("") )
```

- [ ] **Step 2: 运行 XCTest 并确认失败**

- [ ] **Step 3: 按目标设备 CPU 平台选择 SDK 表盘通道**

Implementation: 只在 `dialCount`/`marketDialCount`/`photoDialCount` 与平台支持同时满足时加入 `integratedFeatures`；传输前校验本地文件、尺寸和回调超时。

- [ ] **Step 4: 真机读取当前表盘，传输测试表盘，切回原表盘**

Expected: 进度 0–100；失败返回明确错误；原表盘可恢复。

### Task 8: 能力表、全量验证和交接

**Files:**
- Modify: `ios/Runner/AppDelegate.swift`
- Modify: `docs/device-feature-verification-20260812.md`
- Modify: `docs/HANDOFF-20260812.md`

**Interfaces:**
- Produces: 与真实实现一致的 `features` 和 `integratedFeatures`，以及完整真机测试记录。

- [ ] **Step 1: 为能力交集行为添加 Flutter 测试**

```dart
expect(capabilities.supportsFeature(DeviceFeature.camera), isTrue);
expect(capabilities.isIntegrated(DeviceFeature.camera), isTrue);
```

- [ ] **Step 2: 运行并确认当前 iOS 默认能力不满足测试场景**

- [ ] **Step 3: 更新 iOS 能力表，仅公开实现且设备支持的能力**

- [ ] **Step 4: 运行完整验证**

Run: `flutter analyze --no-pub`

Run: `flutter test --no-pub`

Run: `xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=赛电 iOS 调试'`

Run: `flutter build ios --debug --no-pub`

Run: `git diff --check`

- [ ] **Step 5: iPhone 与目标手表全流程回归并恢复设置**

Expected: 安装启动、扫描连接、同步、测量、运动与所有设备功能逐项有真实结果；外部 DNS、服务端合同、正式签名和 SDK 授权单列。
