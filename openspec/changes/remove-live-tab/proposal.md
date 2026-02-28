## 为什么

简化应用主界面，专注于点播视频内容体验。直播功能使用频率较低，且与核心视频点播功能定位不同，移除后可以让主 Tab Bar 更加简洁清晰。

## 变更内容

- **BREAKING** 移除主 Tab Bar 中的"直播" Tab
- 移除 `LiveViewController` 及其相关 UI 入口
- 保留直播相关的底层代码（`LivePlayerViewController`、`LiveDanMuProvider` 等），以便将来通过其他入口访问
- 调整 Tab Bar 布局，重新排列剩余的 6 个 Tab（推荐、热门、排行榜、关注、收藏、我的）

## 功能 (Capabilities)

### 新增功能

无新增功能。

### 修改功能

- `main-navigation`: 主导航结构从 7 个 Tab 减少到 6 个 Tab，移除"直播"入口

## 影响

### 代码影响
- **主要文件**: 
  - `BilibiliLive/BLTabBarViewController.swift` - 移除 LiveViewController 实例化和 Tab 添加代码
  
- **保留但不再使用的模块**:
  - `BilibiliLive/Module/Live/LiveViewController.swift` - 直播列表视图
  - `BilibiliLive/Module/Live/LivePlayerViewController.swift` - 直播播放器（保留，可能用于其他入口）
  - `BilibiliLive/Module/Live/LivePlayerViewModel.swift` - 直播逻辑
  - `BilibiliLive/Module/Live/LiveDanMuProvider.swift` - 直播弹幕
  - `BilibiliLive/Module/Live/BrotliDecompressor.swift` - 弹幕解压

### 用户影响
- **BREAKING** 用户无法从主界面直接访问直播功能
- Tab Bar 从 7 个减少到 6 个，界面更简洁
- 不影响其他功能的正常使用

### 数据影响
- UserDefaults 中保存的 `selectedIndex` 可能需要处理（当前选中的是直播 Tab 时）
- 无数据丢失或迁移需求

### 依赖影响
- 无外部依赖变更
- 无 API 变更
