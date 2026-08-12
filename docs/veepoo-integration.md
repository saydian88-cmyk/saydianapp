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
- `startSport` / `stopSport` / `readSportRecords`
- `readAutoMeasureSettings` / `setAutoMeasureSetting`
- `readHeartRateWarning` / `setHeartRateWarning`
- 事件流：连接状态、同步进度、健康记录、设备错误

官方仓库已确认并锁定：

- Android：`HBandSDK/Android_Ble_SDK`，
  commit `a3c02015aa9130ab1ae34c93ae0b04ecbcbfe408`，
  `vpprotocol-2.3.77.15.aar` + `vpbluetooth-1.20.aar`。
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
3. `VPOperateManager.init(applicationContext)` 会替换 SDK 静态单例，因此必须先初始化、再
   重新获取并缓存 `getInstance()`；禁止继续使用初始化前的旧实例。
4. 扫描严格使用官方 `startScanDevice(duration, SearchResponse)`；只缓存并展示 SDK
   返回的本轮 `SearchResult`，连接前调用 `stopScanDevice()`。不再把 Android 原生全量
   BLE 扫描结果送入 Veepoo SDK。
5. 连接只使用同一 `SearchResult.address` 和真实 `SearchResult.name`；名称为空时调用
   SDK 的无名称重载，不填充 W9、赛电设备或手工 MAC 等替代值。
6. 首次手动连接固定为 `setDeviceShowConfirm(true)` → `connectDevice` → GATT 成功 →
   Notify 成功 → `confirmDevicePwd` → `syncPersonInfo`。仅 `CHECK_SUCCESS` 和
   `CHECK_AND_TIME_SUCCESS` 算认证成功；确认超时后主动断开。基础资料或首次历史数据
   同步失败不再把已经完成的协议认证误判成连接失败。
7. Flutter 与 Android 两层均保持串行命令队列；官方文档明确说明设备不支持多个耗时
   指令并发。
8. Android 12+ 只请求 `BLUETOOTH_SCAN` 与 `BLUETOOTH_CONNECT`，Android 11 及以下请求
   精确定位；Manifest 按官方文档保留 `neverForLocation`、`BLUETOOTH_ADVERTISE`、两项
   BLE feature 与 `BluetoothService`。
9. SDK 已连接同一地址、但桥接没有完成认证态时，必须先断开再完整重连；否则 SDK 会
   直接返回且不触发本次连接回调。量产手表仍需验证 Android 8、12 和最新版本的扫描、
   重连、运动模式及自动检测设置。
10. 历史健康数据按官方新版 Demo 串行读取：先 `readSleepData`，完成后读取日常数据。
    `originProtocolVersion` 为 3 或 5 时必须使用 `IOriginData3Listener`，其他版本使用
    `IOriginDataListener`。禁止在 V3/V5 设备上继续依赖 `readAllHealthData` 的原始数据
    完成回调；同步超时按“连续无数据/无进度”的空闲时间计算，并在断开或换表时废弃旧回调。
11. 设备页“同步数据”用于重新读取手表历史数据；云端上传由数据读取成功后的后台任务
    独立执行。固件版本取自密码认证返回的 `PwdData.deviceVersion`，不再沿用扫描阶段的
    空设备信息。

### 杰理平台兼容边界

- JL7013A7 是芯片平台，不是 App 协议。相同芯片只有在固件实现 Veepoo/HBand 广播、
  GATT、Notify 和密码认证流程时，才能由本 SDK 完成连接。
- 官方 `startScanDevice` 会过滤非 Veepoo/HBand 设备，因此未通过协议广播筛选的普通
  BLE 设备不会展示，也不会被盲目送入 `connectDevice`。
- 是否属于杰理平台只在协议认证后通过 `isJLCPUPlatform()` 判定，业务能力由 SDK 功能包
  驱动，不按 W8/W9/W9S 或名称正则判断。
- 若官方 Demo 与本 App 在同一手机上都看不到目标手表，需要核对手表是否被其他客户端
  占用、当前广播格式和 Veepoo 协议授权；不能仅凭“同芯片”在 App 侧强行兼容。

## iOS

1. `ios/Runner/Vendor` 已锁定唯一协议分支和官方 Demo 的芯片配套 Framework。
2. Xcode 已配置链接与必要的 Embed & Sign；FMDB/MJExtension 版本由 `ios/Podfile` 锁定。
3. `AppDelegate.swift` 保持 MethodChannel 返回值与 Flutter 类型一致，并由 Flutter 串行
   队列约束设备命令。
4. 仅启用确有业务需要的后台 BLE 模式，不承诺 iOS 被强制终止后的持续同步。
5. iOS 的运动模式和自动检测设置 selector 尚未在 Windows 环境验证，当前明确返回
   `SPORT_NOT_CONFIGURED` / `DEVICE_SETTINGS_NOT_CONFIGURED`；需在 macOS 使用目标手表
   完成 SDK selector、权限、恢复、重连与测量测试。

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
