# 内测版验证记录

验证日期：2026-07-30

## 已通过

- `dart analyze lib test`：无问题。
- `flutter test`：11 项测试全部通过。
- Android debug APK：构建通过。
- Android release APK：构建通过，APK v2 签名校验通过。
- Android release AAB：构建通过。
- 包名：`cc.saidian.app`
- 版本：`0.1.0+1`
- Android：`minSdk 26`、`targetSdk 36`、`compileSdk 36`

## 构建产物

- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

校验值：

- release APK SHA-256：`5261145DA7BECA853CDF51B7D60DE80A3408EEDB1EF530B68B4569982897C4EE`
- release AAB SHA-256：`0519A62A1D2E65156331924470214CF18DEB08E4AEC91A19C89F1EC2E82A26A0`

## 尚未闭环

- release APK/AAB 当前使用调试签名，只允许内部测试；商店发布签名未配置。
- HBandSDK 官方 Android/iOS/小程序仓库及最新提交已锁定；授权 SDK 文件、目标手表和
  固件尚未完成量产确认，原生桥当前会明确返回 `SDK_NOT_CONFIGURED`。
- iOS 工程与 CI 已配置，但 Windows 无法执行 Xcode Archive；需在 macOS CI 或 Mac 真机环境验证。
- 后台批量健康同步、刷新 Token、设备绑定/解绑、注销账号、推送注册等接口仍按“未配置”处理。
- 正式用户协议、隐私政策、Apple Developer、推送和商店账号均未配置。
