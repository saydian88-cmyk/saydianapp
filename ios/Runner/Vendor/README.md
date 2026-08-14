# Veepoo iOS SDK

官方来源：<https://github.com/HBandSDK/iOS_Ble_SDK>

当前锁定提交：`2e25bde67031d7d89e3c6d8d9f9dc76204d9fabe`（2026-07-28），
提交说明中的协议版本为 `2.2.96.15`。

本项目已获得合作客户授权，并按官方 Demo 锁定 `VeepooBleSDK.framework` 及其芯片配套
Framework。MJExtension 3.0.15.1 由 `ios/Podfile` 锁定；FMDB 2.7.12 由
`sqflite_sqlcipher` 经 `ios/Podfile.lock` 解析锁定。

不要同时混用 `2.0.43.15`、`2.1.XX.15`、`2.2.XX.15` 或“兼容汇顶旧固件”目录中的
不同 `VeepooBleSDK.framework`。这些二进制仅限赛电 App 调用，禁止脱离本项目再分发。

## 已知官方二进制问题

HBand 原始 `JLDialUnit.framework`（动态库）和 `JL_BLEKit.framework`（静态库）同时定义：

- `JL_Tools`
- `JL_Timer`
- `JLModel_File`

2026-08-13 已核对本项目的
`JLDialUnit.framework` 和 `JL_BLEKit.framework` 与官方 `HBandSDK/iOS_Ble_SDK`
仓库 `master` 中 Demo 的对应二进制 SHA-256 完全一致，官方 Demo 也同时
链接并嵌入这两套依赖。

项目启用云创插件后，最终包改用云创的新版杰理动态库，不再链接这两套 HBand
旧依赖，因此上述三个旧重复类不会进入最终运行时。原始 framework 文件仍只读保留。

## SDK 版本边界

本项目当前集成的 Veepoo 主 SDK 为 `2.2.96.15`。2026-08-13 官方仓库
`master` 已是 `2.2.98.15`；`2.2.97.15` 和 `2.2.98.15` 的官方提交说明均为
“部分项目付费功能授权变更”。

因此本轮不自动替换主 SDK 二进制。升级前必须先确认赛电项目的厂商授权，再做全量真机回归。

## 云创共存兼容层

启用云创插件后，最终 App 使用云创固定提交中的新版杰理动态 Framework。
Runner 不再链接或嵌入同名的旧版 `JL_BLEKit`、`JLDialUnit`、`ZipZap` 和 `DFUnits`。

`JLLegacyBitmapCompat.a` 是从只读 HBand `JL_BLEKit.framework` 的 arm64 静态片段
机械提取的兼容归档，仅含 `BitmapTool.o` 与 `bmp_convert.o`。它只补齐
`VeepooBleSDK` 仍引用、而云创新版已删除的位图转换符号，避免整库链接导致重复类。

该归档 SHA-256：
`978564B6AAF6FE004741F3FBFC96F4A955E4B4EF5DB531BE9262BB151F53BE21`。
