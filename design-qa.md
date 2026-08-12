# 赛电 App 原型与视觉验收

日期：2026-08-12

## 验收口径

- 功能流程以 `http://sdapp.saidian.cc/` 为准，视觉以蓝湖最新画板为准。
- Android 实机渲染统一使用 `390 x 844` 视口；另以 Widget 测试覆盖 `375 x 812`。
- 对比图均为左侧设计参考、右侧当前 App，双方已归一到相同视口。
- 接口和手表未提供的能力只展示可理解的不可用状态，不伪造成功、数据或支付结果。

## 同视口证据

总览：`build/ui-audit-20260812/39-final-ui-comparison-contact-sheet.png`

| 页面 | 设计参考 | App 截图 | 合并对比 |
| --- | --- | --- | --- |
| 登录 | `build/ui-audit-20260812/reference-login-390x844.png` | `build/ui-audit-20260812/37-release-login-390x844.png` | `build/ui-audit-20260812/compare-login-390x844.png` |
| 首页 | `build/ui-audit-20260812/reference-home-390x844.png` | `build/ui-audit-20260812/32-implementation-home-390x844.png` | `build/ui-audit-20260812/compare-home-390x844.png` |
| 健康 | `build/ui-audit-20260812/reference-health-390x844.png` | `build/ui-audit-20260812/33-implementation-health-390x844.png` | `build/ui-audit-20260812/compare-health-390x844.png` |
| AI | `build/ui-audit-20260812/reference-ai-390x844.png` | `build/ui-audit-20260812/34-implementation-ai-390x844.png` | `build/ui-audit-20260812/compare-ai-390x844.png` |
| 设备未连接 | `build/ui-audit-20260812/reference-device-unconnected-390x844.png` | `build/ui-audit-20260812/35-implementation-device-390x844.png` | `build/ui-audit-20260812/compare-device-unconnected-390x844.png` |
| 我的 | `build/ui-audit-20260812/reference-profile-390x844.png` | `build/ui-audit-20260812/36-implementation-profile-390x844.png` | `build/ui-audit-20260812/compare-profile-390x844.png` |

## 对比迭代

### 第一轮

- 清除正式页面中的连接实现、开发状态、原始错误和接口术语。
- 将五栏导航、页面边距、卡片圆角、按钮形态、字号层级和空白背景统一到蓝湖的紧凑布局。
- 登录、启动页和桌面图标统一使用项目中的真实赛电 Logo 素材。
- 设备页按原型顺序补齐表盘和设备功能入口，并让未连接状态仍能说明每项能力需要什么条件。

### 第二轮

- 修正健康页在窄视口下的导航和长列表可见区域。
- 收紧登录页垂直节奏，使协议确认区在 Release 首屏完整可见。
- 将健康详情、共享管理、密码找回、反馈、客服、关于、购物车和售后等入口接到明确页面。
- 设备功能统一按能力状态显示，已接通的查找手表和屏幕亮度执行真实操作，其余入口不会伪造完成结果。
- 新增 `375 x 812` 全五栏无溢出测试，并保留 `390 x 844` 的页面流程测试。

## 分级结论

- P0：0。未发现阻断主流程、页面空白、崩溃或不可返回问题。
- P1：0。未发现关键控件无响应、正式界面技术词外露或关键内容被裁切。
- P2：0 个未处理项。保留的视觉差异均属于明确的产品取舍：当前登录继续使用已有账号密码接口；设备未连接页提前展示功能清单，避免用户连接后才知道可用内容。

## 验收结果

Android 模拟器关键页面视觉验收通过。真实手表能力、Android 目标手机及 iPhone 的硬件闭环需要在对应设备上继续验证；该边界不以截图或模拟数据代替。
