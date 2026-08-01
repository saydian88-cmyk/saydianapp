# 内测版验证记录

验证日期：2026-08-01

## 已通过

- `flutter analyze --no-pub`：无问题。
- `flutter test`：11 项测试全部通过。
- Veepoo Android AAR 真实 Kotlin 编译：通过。
- Android release APK：构建通过（67.4 MB），APK v2 签名校验通过。
- Android release AAB：构建通过（57.6 MB）。
- 包名：`cc.saidian.app`
- 版本：`0.1.0+1`
- Android：`minSdk 26`、`targetSdk 36`、`compileSdk 36`

## 构建产物

- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

校验值：

- release APK SHA-256：`605051AC093AE316E7826293E21518654C60E306842FA35FBDB3A1F69E06F0F2`
- release AAB SHA-256：`4F6F0871D856B01E7D1A424C4E9408DCDF69FE77622C611EA45A0300F01F7C63`

## 尚未闭环

- release APK/AAB 当前使用调试签名，只允许内部测试；商店发布签名未配置。
- HBandSDK Android/iOS 授权二进制与双端原生桥已锁定；目标手表型号和固件仍需量产
  样机完成扫描、连接、同步、测量和重连验收。
- iOS Framework、Pod 依赖和 Xcode 链接配置已完成，但 Windows 无法执行 Xcode
  Archive；需在 macOS CI 或 Mac 真机环境验证并签名。
- 后台批量健康同步、刷新 Token、设备绑定/解绑、注销账号、推送注册等接口仍按“未配置”处理。
- 正式用户协议、隐私政策、Apple Developer、推送和商店账号均未配置。
