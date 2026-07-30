# Veepoo SDK 接入闸门

## 当前状态

Flutter、Android 和 iOS 的桥接契约已经固定：

- `scanDevices`
- `connect`
- `disconnect`
- `getCapabilities`
- `syncHealthData`
- `startMeasurement`
- `stopMeasurement`
- 事件流：连接状态、同步进度、健康记录、设备错误

官方仓库已确认并锁定：

- Android：`HBandSDK/Android_Ble_SDK`，
  commit `773759d71d0c9d8003d7267c0e319d3167862410`，
  `vpprotocol-2.3.74.15.aar` + `vpbluetooth-1.20.aar`。
- iOS：`HBandSDK/iOS_Ble_SDK`，
  commit `2e25bde67031d7d89e3c6d8d9f9dc76204d9fabe`，
  最新提交说明为 `2.2.96.15`。
- 小程序：`HBandSDK/WeChat_Mini_Program_Ble_SDK`，
  commit `f24c35d020e989d6fa147dbbd6f2d81bbf6ded20`，SDK `1.1.19`。

当前原生实现仍安全返回 `SDK_NOT_CONFIGURED`。官方 Android README 明确写明 SDK 仅供
合作客户使用；没有目标型号、匹配固件和合作方授权确认时，不把公开 Demo 二进制直接
提交到 App 仓库，也不把未上手表验证的调用标记为可用。

## Android

1. 向 Veepoo 确认目标型号所需的协议分支、芯片依赖和量产授权范围。
2. 按 `android/app/libs/README.md` 放入完整授权文件集。Gradle 已实现完整性检测，
   缺少任何必需 AAR 时会停止构建。
3. 在 `MainActivity.kt` 中新增 `VPOperateManager` 适配器，替换
   `UnconfiguredVeepooAdapter`。
4. 调用顺序固定为 `init(applicationContext)` → `startScanDevice` →
   `connectDevice` → Notify 成功 → `confirmDevicePwd` → `syncPersonInfo`。
5. 必须保持单线程命令队列；官方文档明确说明设备不支持多个耗时指令并发。
6. 使用量产手表验证 Android 8、12 和最新版本的权限、重连、后台恢复和系统杀进程。

## iOS

1. 按 `ios/Runner/Vendor/README.md` 选择唯一协议分支的
   `VeepooBleSDK.framework`，并加入匹配芯片所需的 Framework。
2. 在 Xcode 中配置 Embed & Sign、Objective-C bridging header 和厂商要求的链接参数。
3. 在 `AppDelegate.swift` 的串行队列后接入 Objective-C SDK，保持 MethodChannel
   返回值与 Flutter 类型一致。
4. 仅启用确有业务需要的后台 BLE 模式，不承诺 iOS 被强制终止后的持续同步。
5. 使用真机完成 iOS 13、16 和最新版本的权限、恢复、重连与测量测试。

官方主流程对应 `VPBleCentralManage.sharedBleManager()` →
`veepooSDKStartScanDeviceAndReceiveScanningDevice` → `veepooSDKConnectDevice` →
`veepooSDKSynchronousPassword`。完成密码认证后才能从 `peripheralManage` 读取历史数据
或开始手动测量。

## 统一数据约束

厂商回调必须先映射为 `HealthRecord`，包含指标、单位、测量时间、时区、设备 ID、
固件版本、质量、来源和原始格式版本。无法确认单位或质量的数据不得上传。

ECG、HRV、身体成分和血液成分默认关闭，只有在目标型号能力与后台字段同时通过双端
真机验证后才加入 `DeviceCapabilities.metrics`。

小程序 SDK 保留作为 Saydian 现有小程序的参考实现，不嵌入 Flutter App。官方说明
mpvue、uni-app、Taro 等二次编译可能破坏 SDK 模块和执行上下文，故 App 仍采用
Flutter + Android/iOS 原生桥。
