# 首页设计 QA

## 对比目标

- source visual truth path: `C:\Users\admin\AppData\Local\Temp\codex-clipboard-f746bcd5-fa88-432c-a816-a8dcaf4ac6fe.png`
- implementation screenshot path: `E:\saydian\赛电app\docs\saidian-home-device-20260818.png`
- side-by-side comparison: `E:\saydian\赛电app\docs\home-visual-comparison-20260818.png`
- state: 已登录首页；真机显示真实账号“测试00”，健康数据为空；参考图使用演示健康数值。
- implementation device: Huawei JAD-AL00，Android 12。
- source pixels: 853 × 1844；按 iOS 2× 设计稿理解，约 426.5 × 922 逻辑像素。
- implementation pixels: 1228 × 2700；540 dpi，约 364 × 800 逻辑像素。
- density normalization: 对比图仅将真机截图缩放到 853 × 1844 后并排，未将不同逻辑宽度误当成 1:1 像素差异。

## Full-view comparison evidence

完整并排图确认以下结构与参考图一致：

- 顶部品牌 Logo、问候语、状态副标题和通知入口。
- 红金暖色 AI 健康管家主卡，左侧医生插画、右侧说明和“马上提问”。
- 远程关爱、健康百科、健康预警、赛电商城四入口。
- 健康数据标题、日期、全部数据入口。
- 血压、心率、血氧、体温 2 × 2 健康卡。
- 底部仅保留健康、设备、我的三栏导航。

真机逻辑宽度比参考图窄约 15%，首屏只露出第一排健康卡；第二排通过自然滚动可见。这是设备尺寸差异，不是截断或溢出。

## Focused region comparison evidence

重点检查了顶部、AI 主卡、四功能入口、健康标题和底部导航：

- Fonts and typography: 真机使用 Android 中文系统字体，参考图接近 iOS 中文系统字体；字号层级、粗细和可读性一致，真机略粗略大，符合既定适老化要求。未发现截断或不可读文字。
- Spacing and layout rhythm: 横向边距、圆角、卡片分区和区块顺序一致；较窄真机上的纵向密度更高，但 1.5×/2× 系统字体回归无 RenderFlex 溢出。
- Colors and visual tokens: 主红、暖白、金色描边、绿色状态和蓝色趋势色与参考方向一致；品牌红与成功/预警语义色保持分离。
- Image quality and asset fidelity: 首页使用真实赛电 Logo；AI 医生为项目专用生成位图，裁切清晰，无占位图、字符图或代码绘图。
- Copy and content: 问候语、AI 文案、按钮、四入口、健康数据与三栏导航均与参考图一致。日期与账号按真机实时数据显示。

## Findings

- [P3] 参考图与真机使用不同系统字体和逻辑宽度。
  - Evidence: 参考图约 426.5 逻辑像素宽，真机约 364；Android 字体比参考图更粗。
  - Impact: 只影响首屏可见健康卡数量，不影响结构、滚动或操作。
  - Follow-up: 如后续指定统一字体文件或固定目标机型，再做逐像素微调。

- [P3] 四个功能图标使用 Material 图标库中的最近匹配图标。
  - Evidence: 入口含义、颜色和层级一致，但图标造型不是参考图中的定制 3D 图标。
  - Impact: 不影响识别和使用。
  - Follow-up: 客户提供正式图标素材后可直接替换。

## Comparison history

- Iteration 1: 参考图与真机首页完成同图并排检查；未发现可执行的 P0、P1 或 P2 差异，因此无需视觉返工。
- Post-fix evidence: 本轮首页实现截图即为最终证据；全量 111 项 Flutter 测试、2× 字体回归和 Android Release 真机构建通过。

## Primary interactions checked

- AI 健康管家“马上提问”。
- 远程关爱、健康百科、健康预警、赛电商城。
- 全部数据二级页和运动入口。
- 健康、设备、我的三栏导航。
- 设备搜索页商城入口、我的页添加设备/AI 提问、退出登录。
- Release 启动日志未发现 Flutter 运行时异常。

## Implementation checklist

- [x] 首页视觉层级与参考图一致。
- [x] 旧健康页保留为全部数据二级页。
- [x] AI 和运动管家不再占用底部导航。
- [x] 三栏导航和适老化字体无溢出。
- [x] 真机截图与参考图完成同图比较。

final result: passed
