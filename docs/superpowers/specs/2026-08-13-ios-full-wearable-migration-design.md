# iOS 可穿戴能力一次性完整移植设计

## 目标

在不改变 Flutter 业务协议、不伪造服务端能力的前提下，把 Android 已落地的手表能力移植到 iOS，并完成 iPhone 15 Pro Max 与目标手表的真机回归。

交付口径是一个完整版本。内部仍按依赖顺序开发和验证，避免蓝牙命令并发、状态污染和不可恢复的设备设置。

## 权威来源

- Flutter 协议：`lib/services/wearable_bridge.dart` 与 `lib/domain/feature_models.dart`。
- Android 对照：`android/app/src/main/kotlin/cc/saidian/saydian_app/MainActivity.kt`。
- iOS SDK：项目内 `ios/Runner/Vendor/VeepooBleSDK.framework/Headers`。
- 官方参考：`HBandSDK/iOS_Ble_SDK` 的 `master` 分支、中文 API 文档与 Demo。
- 业务与接口边界：`docs/HANDOFF-20260812.md`、`docs/device-feature-verification-20260812.md`、`docs/api-gap.md`。

项目内 SDK 二进制与官方仓库当前二进制哈希不同。此次不直接替换合作方 SDK 二进制，先使用项目已交付且可签名运行的版本；只有现有头文件不存在所需接口时，才把 SDK 升级列为外部依赖。

## 范围

### 本次实现

- iOS 运动开始、停止、历史运动记录。
- 自动测量开关、心率过高预警。
- 查找手表、相机遥控。
- 通话设置、联系人、消息通知、闹钟。
- 天气、世界时钟、健康提醒、辅助评估、屏幕显示。
- 系统表盘、照片表盘在本机 SDK 与目标设备真实支持范围内的读取、切换和传输。
- iOS 能力发现、参数映射、错误码、超时和事件回调与 Android/Flutter 对齐。
- 修复已复现的 `TextEditingController` 生命周期异常和 iOS Objective-C 重复类告警。
- 自动化测试、模拟器构建、真机安装和全流程回归。

### 不伪造的外部项

- 后端域名、支付、购物车、售后、密码重置等缺失接口。
- 正式发布证书、正式包名、隐私协议和用户协议正文。
- SDK 付费授权或目标设备固件未开放的功能。
- 天气服务端密钥以本地调试配置读取，不写入版本库。

## 架构

保留现有 `WearableBridge` 方法通道，不改变 Flutter 公共接口。`AppDelegate` 继续负责 Flutter 通道注册，`VeepooWearableAdapter` 负责 SDK 调用和连接状态。

新增纯 Swift 的 `WearablePayloadMapper`，集中处理运动类型、时间、开关、列表和错误输入映射。它不依赖蓝牙，可由 `RunnerTests` 直接单元测试。

所有 SDK 操作先检查连接与设备能力。读取和写入使用一次性回调保护与超时；Flutter 层已有串行队列，iOS 层不并发发出同类设备命令。

```text
Flutter 页面
  -> AppController
  -> MethodChannelWearableBridge 串行队列
  -> AppDelegate 方法分发
  -> VeepooWearableAdapter 能力校验/超时
  -> VeepooBleSDK
  -> 统一 payload / FlutterError / EventChannel
```

## 数据与错误协议

- 功能名称继续使用 `DeviceFeature.wireName`。
- 未连接返回 `NOT_CONNECTED`。
- 设备无能力返回 `FEATURE_UNSUPPORTED` 或现有专项错误码。
- SDK 回调失败返回 `*_READ_FAILED`、`*_WRITE_FAILED` 或 `*_TIMEOUT`。
- 不支持不是空成功；只有“支持但列表为空”才能返回空列表。
- 能力表中的 `integratedFeatures` 仅包含已完成并可调用的功能。
- 相机快门通过 `cameraShutter` 事件通知 Flutter。
- 运动状态通过 `sportState`，传输进度通过 `sportSyncProgress` 或 `deviceFeatureProgress` 通知 Flutter。

## 设备写入与恢复

真机检查前读取并保存可恢复设置快照，包括自动测量、心率预警、通知、闹钟、屏幕、抬腕亮屏、健康提醒和世界时钟。

测试中只创建带明确测试标识的临时联系人、闹钟或世界时钟。回归结束后删除临时项并恢复原设置；表盘只在确认可恢复到原表盘时执行切换。

## 已知缺陷处理

### 添加关爱弹窗控制器已释放

根因是弹窗关闭动画仍可能持有输入框，而函数在 `showDialog` Future 返回后立即释放控制器。修复方式是让有状态弹窗组件拥有并在自身 `dispose` 中释放控制器。

### Objective-C 重复类

先用 `nm`、`otool` 和官方 Demo 的依赖布局确认重复类来自哪个静态/动态 framework 组合，再只移除重复链接的一份。不得通过隐藏运行时告警掩盖问题。

### 热重载挂起

把普通重启可运行与热重载挂起分开诊断。记录 Flutter 工具、VM Service、DDS、Xcode 和设备日志边界；若根因属于 Flutter/Xcode 26.6 工具链，保留可重复的重新启动调试替代路径并记录外部阻塞。

## 验收标准

- `flutter analyze --no-pub` 无问题。
- `flutter test --no-pub` 全部通过，新增回归测试经历失败到通过。
- iOS 模拟器 Debug 构建通过，设备 SDK 能力在模拟器上返回未配置而不崩溃。
- iPhone 真机 Debug 构建、安装、启动和连接通过。
- 目标手表逐项验证读取、写入、错误态和恢复。
- 启动日志不再出现已定位的重复类告警；若官方二进制自身重复，提供符号证据并标为 SDK 阻塞。
- 后端 DNS 或缺少合同的功能明确列为外部问题，不宣称已完成。
