# 赛电 App 原型覆盖表（2026-08-12）

判定顺序：功能流程以原型站为准，视觉以蓝湖最新画板为准，数据只来自现有接口、本机记录和手表实际能力。`暂时不可用`表示入口、页面、输入校验和真实状态已经完成，但没有编造服务端或设备结果。

| 原型范围 | App 页面/入口 | 数据来源 | 当前状态 |
|---|---|---|---|
| 启动页 | `_BootPage` | 本机初始化状态 | 已完成 |
| 登录 | `LoginPage` | 登录接口 | 已完成 |
| 注册/设置密码 | `RegistrationPage` | 注册接口 | 已完成，含两次密码校验和经销商编号选填 |
| 忘记/重置密码 | `PasswordRecoveryPage` | 尚无找回服务 | 页面与手机号校验完成，暂时不可用 |
| 完善资料 | `ProfileEditPage` | 会员资料接口 | 已完成 |
| 首页 | `DashboardPage` | 本机健康记录、目标接口 | 已完成 |
| 消息/消息详情 | `NotificationsPage` / `NotificationDetailPage` | 消息接口 | 已完成 |
| 目标 | `GoalSettingsPage` | 目标接口 | 已完成 |
| 远程关爱/成员 | `CarePage` / `CareMemberPage` | 关爱接口 | 已完成 |
| 共享管理 | `SharingManagementPage` | 已有关爱成员及授权边界 | 已完成，不伪造授权 |
| 健康指标总览 | `HealthPage` | 本机记录、手表能力 | 已完成 |
| 指标历史/单条详情 | `HealthHistoryPage` / `HealthRecordDetailPage` | 本机健康记录 | 已完成 |
| 健康预警 | `HealthWarningPage` | 尚无预警接口 | 空态与健康边界完成 |
| 运动模式/运动中 | `SportSessionPage` | 手表能力 | 已完成 |
| 运动记录 | `SportRecordsPage` | 手表记录 | 已完成 |
| 心率/血氧/血压/体温测量 | `HealthPage` | 手表实时测量 | 按能力启用 |
| 血糖/ECG/HRV/身体成分/血液成分 | `HealthPage` | 手表能力 | 入口与历史页完成，按能力显示 |
| 血压/血糖校准 | `HealthCalibrationPage` | 尚未完成安全写入 | 页面完成，暂时不可用 |
| AI 管家/聊天 | `AiPage` / `AiChatPage` | AI 对话接口 | 已完成 |
| 健康百科/文章 | `AiPage` / `ArticleDetailPage` | 百科接口 | 已完成 |
| 商城搜索/商品 | `ShopHomePage` / `ShopProductPage` | 商城公开接口 | 已完成 |
| 购物车 | `ShoppingCartPage` | 尚无购物车接口 | 页面完成，提供直接购买说明 |
| 下单/地址 | `ShopCheckoutPage` / `ShopAddressBookPage` / `ShopAddressEditPage` | 下单与地址接口 | 已完成 |
| 支付状态 | `ShopPaymentStatusPage` | 订单接口 | 已完成，不伪造支付成功 |
| 订单/订单详情 | `OrdersPage` / `OrderDetailPage` | 订单接口 | 已完成 |
| 物流 | `ShopExpressPage` | 物流接口 | 已完成 |
| 售后 | `AfterSalesPage` | 尚无售后接口 | 页面完成，暂时不可用 |
| 搜索设备三态 | `DeviceSearchPage` | 手表官方扫描结果 | 搜索中、已发现、未发现/失败已完成 |
| 关于设备 | `DeviceInfoPage` | 连接后设备信息和能力 | 已完成 |
| 表盘/照片表盘 | `DeviceFeaturePage` | 手表表盘列表及手机照片 | Android 已接通已安装表盘切换和照片表盘传输；在线表盘商店无可靠资源接口，未伪造 |
| 查找手表 | `DeviceFeaturePage` | Android 手表能力 | Android 已接通开始/停止查找；目标手表待实测 |
| 相机/电话/联系人/消息/闹钟 | `DeviceFeaturePage` | 手表能力及 Android 系统权限 | Android 已接通读写、手表拍照触发和用户选中的消息转发；目标手表待实测 |
| 天气/世界时钟 | `DeviceFeaturePage` | 小程序同源天气服务、当前位置及手表能力 | Android 已接通天气开关、天气数据下发和世界时钟增删；天气密钥仅在构建时注入 |
| 健康提醒/辅助评估 | `DeviceFeaturePage` | 手表能力 | Android 已接通能力读取和设置，不将辅助评估表述为诊断 |
| 健康监测 | `PermissionManagementPage` | 手表自动检测设置 | Android 已有设置；iOS 保持同契约待真机验证 |
| 屏幕显示 | `DeviceFeaturePage` | 手表屏幕能力 | Android 已接通亮度、亮屏时长和抬腕亮屏，按实际能力显示 |
| 我的/资料 | `SettingsPage` / `ProfileEditPage` | 会员资料接口 | 已完成 |
| 单位/目标 | `UnitSettingsPage` / `GoalSettingsPage` | 本机设置、目标接口 | 已完成 |
| 账号/安全 | `AccountSettingsPage` / `SecurityCenterPage` | 账号状态 | 已完成；重置密码暂时不可用 |
| 权限 | `PermissionManagementPage` | 系统权限 | 已完成，提供系统设置入口 |
| 帮助反馈 | `FeedbackPage` | 尚无反馈接口 | 页面和校验完成，暂时不可用 |
| 联系客服 | `CustomerServicePage` | 尚无 App 客服渠道 | 页面完成，暂时不可用 |
| 关于我们 | `AboutSaydianPage` | App 版本和品牌信息 | 已完成 |

## 统一可用状态

- `ready`：可以使用。
- `needsDevice`：连接手表后使用。
- `needsPermission`：允许相关权限后使用，并提供系统设置入口。
- `unsupportedDevice`：当前手表不支持此功能。
- `serviceUnavailable`：此功能暂时无法使用，请稍后再试。

设备诊断、原始状态码和开发日志只保留在原生/调试层，不进入正式页面。
