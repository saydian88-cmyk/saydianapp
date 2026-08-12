# 内测版验证记录

> 本文件是 2026-08-05 的历史验证记录。最新 30 项测试、商城/设备流程和 APK 校验结果
> 请以 [`APP最终测试报告-20260810.md`](APP最终测试报告-20260810.md) 及
> [`HANDOFF-20260812.md`](HANDOFF-20260812.md) 为准。

验证日期：2026-08-05

## 已通过

- `flutter analyze --no-pub`：无问题。
- `flutter test`：12 项测试全部通过，含 390 × 844 手机视口五个核心页布局检查。
- 蓝湖 UI 参考已应用于登录、健康首页、健康指标、设备、远程关爱和个人中心。
- Veepoo Android AAR 真实 Kotlin 编译：通过。
- Android release APK：构建通过（67.15 MB）。
- Android release AAB：构建通过（57.54 MB）。
- 包名：`cc.saidian.app`
- 版本：`0.1.0+1`
- Android：`minSdk 26`、`targetSdk 36`、`compileSdk 36`

## 构建产物

- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

校验值：

- release APK SHA-256：`C382975530E7897B457AE9B8AF6731E534CA7FEC2B46BD10AB4906EADFDFADD3`
- release AAB SHA-256：`D18151A2373B02CFF520D60C119431D8421DE54CEA6F0D34312F5DF2D837915E`

## 尚未闭环

- 2026-08-07 新增的五栏导航、运动模式、AI/订单/账号/权限页面和 Android 蓝牙修复已完成
  静态差异检查与 SDK class 签名核对；当前 Windows 环境没有 Flutter/JDK，尚未重跑
  `flutter analyze`、Widget 测试和 Android 构建，不能沿用上方旧产物作为本次变更的验证证据。

- release APK/AAB 当前使用调试签名，只允许内部测试；商店发布签名未配置。
- HBandSDK Android/iOS 授权二进制与双端原生桥已锁定；目标手表型号和固件仍需量产
  样机完成扫描、连接、同步、测量和重连验收。
- iOS Framework、Pod 依赖和 Xcode 链接配置已完成，但 Windows 无法执行 Xcode
  Archive；需在 macOS CI 或 Mac 真机环境验证并签名。
- 后台批量健康同步、刷新 Token、设备绑定/解绑、注销账号、推送注册等接口仍按“未配置”处理。
- 正式用户协议、隐私政策、Apple Developer、推送和商店账号均未配置。
