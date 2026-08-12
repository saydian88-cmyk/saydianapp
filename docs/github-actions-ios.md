# Windows 开发与 GitHub Actions iOS 测试包配置

## 已配置的构建方式

Windows 用于 Flutter/Dart 开发、Android 调试和提交代码；iOS 编译与签名由 GitHub Actions 的 macOS 26 构建机完成。工作流文件为 `.github/workflows/ios-test-ipa.yml`，使用 Xcode 26.5 和 Flutter 3.44.9，输出可安装到已登记 iPhone 的 Ad Hoc IPA。

工作流支持两种触发方式：

- 在 GitHub 仓库的 `Actions` 页面手动运行 `iOS Ad Hoc Test IPA`。
- 推送名称以 `ios-test-v` 开头的标签，例如 `ios-test-v0.1.0-build.2`。

IPA 和 SHA-256 校验文件会保存为本次运行的 GitHub Actions Artifact，保留 14 天。证书和描述文件只写入构建机的临时钥匙串，任务结束时会清理。

## 1. Windows 开发环境

安装并配置以下工具：

- Git for Windows
- Flutter 3.44.9（stable）
- Android Studio，以及项目所需 Android SDK
- Visual Studio Code 或 Android Studio 的 Flutter/Dart 插件
- 可选：GitHub CLI，用于从命令行配置 Secret 和触发工作流

在项目目录检查环境：

```powershell
flutter --version
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Windows 无法安装 Xcode，因此不能在本机生成或验证 IPA。所有 iOS 编译、CocoaPods 安装、签名和导出步骤均在 GitHub 的 macOS 构建机执行。

## 2. 准备 Apple Ad Hoc 签名材料

需要有效的 Apple Developer Program 团队，并在 Apple Developer 后台完成：

1. 注册 App ID，Bundle Identifier 必须是 `cc.saidian.app`。
2. 登记所有测试 iPhone 的 UDID。
3. 创建 `Apple Distribution` 证书。
4. 创建 `Ad Hoc` Provisioning Profile，选择上述 App ID、Distribution 证书和测试设备。
5. 下载 `.mobileprovision` 描述文件，并把带私钥的证书导出为 `.p12`。

如果只有 Windows，可以用 OpenSSL 创建私钥和 CSR：

```powershell
openssl genrsa -out ios_distribution.key 2048
openssl req -new -key ios_distribution.key -out CertificateSigningRequest.certSigningRequest
```

将 CSR 上传到 Apple Developer 后台创建 Distribution 证书，下载 `distribution.cer` 后转换并导出 P12：

```powershell
openssl x509 -inform DER -in distribution.cer -out distribution.pem
openssl pkcs12 -export -inkey ios_distribution.key -in distribution.pem -out ios_distribution.p12
```

妥善保管 `.key`、`.p12` 及其密码。项目已经忽略 `*.p12` 和 `*.mobileprovision`，不要把签名材料提交到 Git。

## 3. 配置 GitHub Actions Secret

在 PowerShell 中把二进制文件转为单行 Base64：

```powershell
$p12Base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path '.\ios_distribution.p12')))
$profileBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes((Resolve-Path '.\Saidian_AdHoc.mobileprovision')))
$p12Base64 | Set-Clipboard
```

打开 GitHub 仓库：`Settings` → `Secrets and variables` → `Actions` → `New repository secret`，依次创建：

| 名称 | 内容 |
| --- | --- |
| `IOS_P12_BASE64` | P12 文件的 Base64；先用上面的 `$p12Base64 \| Set-Clipboard` 复制 |
| `IOS_P12_PASSWORD` | 导出 P12 时设置的密码 |
| `IOS_PROVISIONING_PROFILE_BASE64` | 描述文件的 Base64；用 `$profileBase64 \| Set-Clipboard` 复制 |

可在同一页面的 `Variables` 中创建非敏感变量 `SAYDIAN_API_BASE_URL`。不创建时，构建默认使用 `https://app.saidian.cc`。

工作流会从 Provisioning Profile 自动读取 Team ID、Profile 名称和 UUID，并检查：

- Profile 的 Bundle ID 是否为 `cc.saidian.app`
- 是否包含测试设备
- 是否确实为 Ad Hoc 而非 Development Profile
- Profile 是否仍在有效期内
- P12 是否包含可用的 Distribution 签名身份
- Profile 是否由该 P12 中的证书创建

## 4. 生成 IPA

### GitHub 网页手动运行

1. 推送当前分支和工作流文件到 GitHub。
2. 打开 `Actions` → `iOS Ad Hoc Test IPA` → `Run workflow`。
3. 可填写版本号和构建号；构建号留空时使用 GitHub Run Number。
4. 构建成功后，在任务页面的 `Artifacts` 下载 `saydian-ios-adhoc-<运行号>`。

### 用 Git 标签自动运行

```powershell
git tag ios-test-v0.1.0-build.2
git push origin ios-test-v0.1.0-build.2
```

标签推送后，GitHub Actions 会自动构建。标签只负责触发；App 内的版本默认取 `pubspec.yaml`，构建号默认取 GitHub Run Number。

## 5. 安装到测试 iPhone

Ad Hoc IPA 只能安装到 Provisioning Profile 中已登记 UDID 的设备。

- Apple Configurator：在 macOS 上连接 iPhone，将 IPA 拖入设备。
- Xcode：打开 `Devices and Simulators`，选择设备后安装 IPA。
- 第三方企业内测分发服务：上传 IPA 并按服务指引安装；确认服务的安全与合规要求。

如果需要 TestFlight，必须改用 App Store Connect 分发证书/Profile，并把导出方法改为 App Store Connect；当前工作流专门生成 Ad Hoc 测试包，不会上传 App Store Connect。

## 6. 常见失败原因

- `Missing required GitHub Actions secret`：对应 Secret 未创建、名称拼错，或 Secret 不在当前仓库可用范围。
- `Provisioning profile is for ...`：Profile 的 App ID 与 `cc.saidian.app` 不一致。
- `contains no test devices`：使用了 App Store Profile，或 Ad Hoc Profile 没有勾选设备。
- `valid Apple Distribution signing identity`：P12 不含私钥、密码错误、证书过期或类型不是 Distribution。
- 安装提示设备不受支持：测试 iPhone 的 UDID 没加入 Profile；添加后必须重新生成并替换 Secret。
- `pod install` 失败：先确认 `ios/Podfile` 与 `pubspec.lock` 已提交，再重试任务；依赖源临时故障也可能导致失败。
- Veepoo SDK 编译失败：确认 `ios/Runner/Vendor` 下七个 framework 均已提交，且工作流仍使用 macOS 26 / Xcode 26.5。
