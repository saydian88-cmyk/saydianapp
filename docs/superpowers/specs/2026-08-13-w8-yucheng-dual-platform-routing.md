# W8 系列云创 SDK 双端自动路由设计

## 目标

在不改变现有 Flutter 页面、后端协议和非 W8 设备行为的前提下，
让 W8、W8S、W8 Pro、W8 Ultra、W8 Ultra-R 在 iOS 与 Android 自动使用云创 SDK。

同一台设备一旦由云创连接，后续扫描停止、连接状态、健康同步、测量、运动、设置、表盘和设备控制均只能通过云创接口执行。
其他设备继续使用现有 Veepoo SDK。

## 已确认的设备识别规则

- W8 系列名称为：`W8`、`W8S`、`W8 Pro`、`W8 Ultra`、`W8 Ultra-R`。
- 连接前只可稳定取得蓝牙名称、标识和信号；云创的正式型号查询在连接后。
- 名称比较忽略英文大小写、连续空格和连字符样式；其余字符必须完全一致。
- 不使用 MAC 地址前缀、RSSI 或猜测型号作为路由依据。
- 若旧 SDK 扫描到 W8 名称、云创 SDK 未返回同一设备，则不允许回退连接旧 SDK；返回“W8 设备未被云创 SDK 识别”的可诊断错误。
- 连接后再次用云创 `queryDeviceModel` 验证型号；验证失败或不属于上述集合时立即断开，不发送业务指令。

## 权威来源与版本策略

- 云创官方文档：`https://ycaviation.com/sdk-docs.html`。
- 云创官方 Flutter 插件：`https://gitee.com/yucheng_3/yc_product_plugin`。
- 现有 Flutter 公共协议：`lib/services/wearable_bridge.dart`。
- 现有 iOS/Android Veepoo 实现：`ios/Runner/AppDelegate.swift`、`android/app/src/main/kotlin/cc/saidian/saydian_app/MainActivity.kt`。

云创插件必须固定到官方文档给出的提交 `ed5dabd0850edc5d64bb975c9a2f4d65c1344201`，不跟随 `master`。
SDK 二进制、AAR、framework 与其杰理依赖必须来自同一个已验证的云创插件版本。

## 架构

在 Dart 层引入路由桥接，而不修改既有 `WearableBridge` 对页面暴露的方法名：

```text
AppController
  -> RoutedWearableBridge
       -> VeepooMethodChannelWearableBridge
       -> YuchengWearableBridge
            -> YcProductPlugin 官方 Flutter API
```

`RoutedWearableBridge` 是唯一注入 `AppController` 的实现。
它并行执行两套扫描、合并去重结果，并保存每个展示设备的来源与原始标识。
连接成功后写入 `activeTransport`；除断开外，所有命令只转发给该来源。

两套 SDK 的原生事件在各自适配器中转成现有 `WearableEvent`。
路由器只透传当前连接来源的状态、实时数据和控制事件，扫描事件带上来源标记。

## 设备标识与路由

新增内部运输类型：

```dart
enum WearableTransport { veepoo, yucheng }

class RoutedDevice {
  const RoutedDevice({
    required this.display,
    required this.transport,
    required this.nativeIdentifier,
  });
}
```

对页面的 `DeviceInfo.id` 使用不可冲突的展示标识：

```text
veepoo:<原始地址或 UUID>
yucheng:<原始地址或 UUID>
```

原始标识不写入后端、不作为跨设备永久身份，仅保存在当前扫描会话和已连接会话。
同一物理设备同时被两套扫描发现时，若名称是 W8 系列，保留云创记录；否则保留 Veepoo 记录。

## 云创能力映射

`YuchengWearableBridge` 只把官方 SDK 已报告支持的能力列入 `DeviceCapabilities`。
它将云创调用映射为现有 Flutter 协议：

| 当前桥接能力 | 云创接口类别 |
| --- | --- |
| 扫描、连接、断开、状态 | `scanDevice`、`connectDevice`、`disconnectDevice`、监听蓝牙状态 |
| 设备信息与能力 | 基本信息、型号、MCU、`getDeviceFeature` |
| 健康历史与实时测量 | 健康数据查询、实时数据事件、测量控制 |
| 运动与运动记录 | APP 运动控制、运动数据查询 |
| 设置与提醒 | 用户资料、目标、单位、久坐、告警、通知、闹钟、联系人、屏幕 |
| 查找、相机、天气、表盘 | App 控制、天气、表盘与自定义表盘接口 |

SDK 返回 `unavailable` 时统一映射为 `FEATURE_UNSUPPORTED`，不得返回空成功。
数据字段无法与既有 `HealthRecord`、`SportRecord` 或 `DeviceFeature` 对齐时，返回显式错误并记录原始 SDK 状态，不臆造数据。

## 原生依赖冲突处理

现有项目与云创插件都使用杰理相关库，且 iOS 的 framework 名称、Android 的 AAR 类名存在重叠。
因此接入顺序必须为：

1. 固定云创插件提交并取得该提交对应的全部原生依赖。
2. 列出 iOS `nm`/`otool` 符号和 Android Gradle 依赖树，确认重复模块。
3. 每个平台只保留一套经过编译验证的共享杰理模块；禁止同时链接同名 framework 或重复 dex 类。
4. 分别回归一台既有 Veepoo 手表和一台 W8 设备。

若统一后的杰理组件令旧 Veepoo 编译、启动或连接回归失败，停止替换，不删除旧 SDK，并要求云创提供可与现有 Veepoo 版本共存的官方二进制组合。

## 非目标

- 不修改后端设备绑定、健康数据 API 或产品页面。
- 不声称健康数据具备诊断用途或额外准确度。
- 不通过“先尝试 Veepoo、失败后尝试云创”的方式探测设备。
- 不把未知名称的云创扫描设备自动归入 W8 系列。

## 验收标准

- 五种精确名称均路由到云创；近似名称（如 `W80`、`W8 Pro Max`）不误匹配。
- 非 W8 设备继续通过 Veepoo 连接，既有 Flutter 测试不回归。
- W8 连接后型号二次校验成功，所有设备交互由云创适配器处理。
- 不支持功能返回 `FEATURE_UNSUPPORTED`；没有伪造的健康或设置数据。
- `flutter analyze --no-pub`、`flutter test --no-pub`、iOS Debug 构建和 Android Debug 构建通过。
- iPhone 与 Android 各完成至少一台 W8 和一台既有 Veepoo 手表的扫描、连接、同步、断开回归；写入类测试均在结束后恢复原设备设置。
