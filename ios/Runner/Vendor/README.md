# Veepoo iOS SDK

官方来源：<https://github.com/HBandSDK/iOS_Ble_SDK>

当前锁定提交：`2e25bde67031d7d89e3c6d8d9f9dc76204d9fabe`（2026-07-28），
提交说明中的协议版本为 `2.2.96.15`。

获得合作方授权并确认目标型号/芯片后，把官方
`Framework/2.2.XX.15/VeepooBleSDK.framework` 和该型号实际需要的芯片配套
Framework 放入本目录，再由 macOS/Xcode 完成 Embed & Sign。

不要同时混用 `2.0.43.15`、`2.1.XX.15`、`2.2.XX.15` 或“兼容汇顶旧固件”目录中的
不同 `VeepooBleSDK.framework`。二进制文件继续被 Git 忽略。
