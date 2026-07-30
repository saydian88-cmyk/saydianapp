# 赛电后台 API 缺口

盘点日期：2026-07-29。公开 Apifox 文档共 45 个接口，全部标记为“开发中”；
OpenAPI 顶层安全声明为空，多数会员接口没有明确 Authorization 参数。

## 内测前必须完成

- 所有会员、健康、关爱、订单和文件接口强制 Bearer 鉴权，并统一 401/403 行为。
- 从公开示例移除 Token、手机号、IP、余额和内部账户字段；仍有效的凭据立即轮换。
- 补齐 Token 刷新、服务端退出、密码重置、账号注销。
- 新增设备绑定、解绑、能力、固件和同步游标接口。
- 新增 `POST /api/v1/member/health-records/batch`：
  - JSON 请求，最多 200 条。
  - 必须支持 `Idempotency-Key`。
  - 返回 `accepted`、`rejected[{id, reason}]`、`nextCursor`。
- 远程关爱继续补齐接受、拒绝、逐指标授权、撤销、到期时间和审计记录。
- 用户协议和隐私政策提供正式版本、版本号、发布时间和用户同意记录。

## 客户端兼容策略

现有小程序路由保持不变。App 通过 `SaydianApi` 适配层访问现有登录、注册和关爱接口；
新能力在服务端未提供时抛出 `FeatureNotConfiguredException`，保留本地数据和待上传队列，
界面显示“未配置”，不假报成功。

2026-07-30 已按提供的 Apifox 页面补齐：

- `GET /api/v1/member/care`：获取关爱列表。
- `POST /api/v1/member/care`：使用 Bearer 鉴权和 `multipart/form-data`，
  字段为 `mobile`；客户端添加成功后刷新关爱列表。

Apifox 页面仍标记“开发中”，因此上线前必须在测试环境验证 401、重复添加、手机号不存在、
对方拒绝和撤销后的服务端行为。

## 错误契约

服务端需统一返回：

```json
{
  "code": 422,
  "message": "字段校验失败",
  "data": {
    "errors": {
      "field": ["原因"]
    }
  },
  "timestamp": 1785338748
}
```

至少覆盖 400、401、403、404、409、422、429 和 500；健康数据部分失败不得用 HTTP 200
和空对象掩盖。
