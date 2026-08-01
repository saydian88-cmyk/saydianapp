# Veepoo SDK 接入说明

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

合作客户授权和小程序源码已确认。官方 Android AAR、iOS Framework 及芯片配套依赖已
锁定到本私有 App 仓库；原生桥已按官方 Demo 完成直接调用。尚未经过目标量产手表验证的
功能不作真机通过声明。

## Android

1. `android/app/libs` 已锁定完整授权文件集；Gradle 会校验完整性，缺少任何必需 AAR
   时停止构建。
2. `MainActivity.kt` 使用 `VPOperateManager` 实现直接适配。
3. 调用顺序固定为 `init(applicationContext)` → `startScanDevice` →
   `connectDevice` → Notify 成功 → `confirmDevicePwd` → `syncPersonInfo`。
4. Flutter 与 Android 两层均保持串行命令队列；官方文档明确说明设备不支持多个耗时
   指令并发。
5. 使用量产手表验证 Android 8、12 和最新版本的权限、重连、后台恢复和系统杀进程。

## iOS

1. `ios/Runner/Vendor` 已锁定唯一协议分支和官方 Demo 的芯片配套 Framework。
2. Xcode 已配置链接与必要的 Embed & Sign；FMDB/MJExtension 版本由 `ios/Podfile` 锁定。
3. `AppDelegate.swift` 保持 MethodChannel 返回值与 Flutter 类型一致，并由 Flutter 串行
   队列约束设备命令。
4. 仅启用确有业务需要的后台 BLE 模式，不承诺 iOS 被强制终止后的持续同步。
5. 在 macOS 执行 `pod install` 后，使用真机完成 iOS 13、16 和最新版本的权限、恢复、
   重连与测量测试。

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
