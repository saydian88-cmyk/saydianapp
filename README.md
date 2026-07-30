# Saydian 赛电 App

赛电健康管理 App 的 Flutter 双端工程。Android 通过 Kotlin、iOS 通过
Swift/Objective-C 适配 Veepoo SDK；Flutter 层共享页面、状态机、健康数据模型、
加密本地存储、离线同步和现有赛电后台 API 适配。

## 当前可用范围

- 账号登录、注册和安全会话存储
- 健康首页、核心指标空态与历史记录展示
- 设备扫描、连接、能力读取、同步和测量的统一 MethodChannel 契约
- SQLCipher 本地健康数据库与 200 条/批的幂等补传队列
- 远程关爱隐私默认模型：未接受、未逐项授权时不共享
- Android 8+ 与 Android 12+ 蓝牙权限配置
- iOS 13+ 蓝牙用途说明和 `bluetooth-central` 后台模式
- 单元测试、Widget 测试、Android/iOS CI

当前没有 Veepoo 合作方二进制库和量产样机。原生桥因此使用安全的
`SDK_NOT_CONFIGURED` 适配器；设备页会显示“未配置”，不会生成虚假设备或健康数据。
Android/iOS/小程序官方仓库和 2026-07-28 最新提交已锁定，Gradle 已支持完整 SDK
文件集自动检测；具体版本及校验值见接入说明。

关爱模块已支持现有 `GET /api/v1/member/care` 和
`POST /api/v1/member/care`（Bearer + multipart `mobile`）。审核、逐指标授权、
撤销和审计仍以服务端后续契约为准。

## 本地开发

```powershell
$flutter = 'F:\Codex\home\tools\flutter\bin\flutter.bat'
& $flutter pub get
& $flutter test
& $flutter run --dart-define-from-file=config/dev.json
```

首次使用时复制 `config/dev.json.example` 为 `config/dev.json`。配置文件、签名材料、
Token、密码和厂商授权库不得提交到代码库。

## 构建

```powershell
& $flutter build apk --debug
& $flutter build appbundle --release
```

iOS 必须在 macOS/Xcode 环境执行：

```bash
flutter build ios --release --no-codesign
```

正式签名、TestFlight 和商店提交需要另行配置 Apple Developer、Android 商店签名、
隐私政策、用户协议和推送/支付材料。

## 接入闸门

- [Veepoo 原生 SDK 接入说明](docs/veepoo-integration.md)
- [现有后台 API 缺口](docs/api-gap.md)
- 小程序源码、目标手表型号/芯片/固件和至少两台量产样机仍待提供
- 正式内测前必须替换线上空白隐私政策和占位用户协议

所有健康结果仅供健康管理参考，不用于诊断或治疗。
