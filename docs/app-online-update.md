# App 在线更新配置

## 接入方式

App 的“关于我们 → 检查更新”读取一个 HTTPS JSON 清单。构建时通过下列参数配置正式地址：

```bash
flutter build ipa \
  --dart-define=SAYDIAN_UPDATE_MANIFEST_URL=https://your-domain.example/app-update.json
```

未配置时，页面会明确显示“在线更新服务暂未配置”，不会伪造检查成功。

## 清单格式

```json
{
  "android": {
    "version": "0.1.13",
    "build": 15,
    "download_url": "https://your-domain.example/download/saydian.apk",
    "release_notes": "稳定性与兼容性优化",
    "force_update": false
  },
  "ios": {
    "version": "0.1.13",
    "build": 15,
    "download_url": "https://apps.apple.com/app/idYOUR_APP_ID",
    "release_notes": "稳定性与兼容性优化",
    "force_update": false
  }
}
```

`version`、`build` 和 `download_url` 必填。清单地址和下载地址都必须使用 HTTPS。

## iOS 说明

iOS 正式版不能在 App 内下载并自行安装新版。`ios.download_url` 应配置为正式 App Store 产品页；检测到新版后，App 会交给系统打开 App Store。

发布前需要由产品或运维提供正式的清单地址、App Store App ID 和 Android 下载地址。当前交付源码没有这些生产配置，因此代码不预填虚假地址。
