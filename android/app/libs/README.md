# Veepoo Android SDK

官方来源：<https://github.com/HBandSDK/Android_Ble_SDK>

当前锁定提交：`773759d71d0c9d8003d7267c0e319d3167862410`（2026-07-28）。

获得合作方授权并确认目标型号后，将下列文件完整放入本目录：

- `vpprotocol-2.3.74.15.aar`
- `vpbluetooth-1.20.aar`
- `JL_Watch_V1.13.1_11214-release.aar`
- `jl_rcsp_V0.7.2_527-release.aar`
- `jl_bt_ota_V1.10.0_10931-release.aar`
- `BmpConvert_V1.6.0_10604-release.aar`
- `abpartool-release.aar`

Gradle 会自动检测完整文件集；只放入部分文件时会直接停止构建并列出缺失项。
二进制文件继续被 Git 忽略，不进入公开仓库。

当前官方文件校验值：

- `vpprotocol-2.3.74.15.aar` SHA-256：
  `8756C89934F19024A40436D97DE3A16F0CE4D80EE779146A2720E53C3B0AAB1A`
- `vpbluetooth-1.20.aar` SHA-256：
  `26D7037238D18A28AC373A511B7A2ABDFAC2A405E01564F90A89C926B5B48BD8`

注意：官方 README 同时写明 SDK 仅供合作客户使用。公开可下载不等于已取得量产授权。
