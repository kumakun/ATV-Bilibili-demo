## 为什么

进一步精简应用界面，专注于用户个性化内容。推荐、热门、排行榜等发现型功能使用频率相对较低，移除后可以让主界面更加聚焦于用户关注和收藏的内容，提升个人化体验。

## 变更内容

- **BREAKING** 移除主 Tab Bar 中的"推荐" Tab
- **BREAKING** 移除主 Tab Bar 中的"热门" Tab  
- **BREAKING** 移除主 Tab Bar 中的"排行榜" Tab
- 移除 `FeedViewController`、`HotViewController`、`RankingViewController` 的 UI 入口
- 保留这些 ViewController 的底层代码，以便将来通过其他入口访问
- 主 Tab Bar 从 6 个 Tab 精简为 3 个 Tab：关注、收藏、我的

## 功能 (Capabilities)

### 新增功能

无新增功能。

### 修改功能

- `main-navigation`: 主导航结构从 6 个 Tab 进一步减少到 3 个 Tab，移除"推荐"、"热门"、"排行榜"入口

## 影响

### 代码影响
- **主要文件**: 
  - `BilibiliLive/BLTabBarViewController.swift` - 移除 FeedViewController、HotViewController、RankingViewController 实例化和 Tab 添加代码
  
- **保留但不再使用的模块**:
  - `BilibiliLive/Module/ViewController/FeedViewController.swift` - 推荐视图
  - `BilibiliLive/Module/ViewController/HotViewController.swift` - 热门视图
  - `BilibiliLive/Module/ViewController/RankingViewController.swift` - 排行榜视图

### 用户影响
- **BREAKING** 用户无法从主界面直接访问推荐、热门、排行榜功能
- Tab Bar 从 6 个减少到 3 个，界面极度简化
- 应用变为纯个人化内容管理工具（关注、收藏）
- 不影响"关注"、"收藏"、"我的"三个核心功能的正常使用

### 数据影响
- UserDefaults 中保存的 `selectedIndex` 需要重新映射：
  - 旧索引 0-2（推荐、热门、排行榜）→ 新索引 0（关注）
  - 旧索引 3（关注）→ 新索引 0
  - 旧索引 4（收藏）→ 新索引 1
  - 旧索引 5（我的）→ 新索引 2
- 无数据丢失或迁移需求

### 依赖影响
- 无外部依赖变更
- 无 API 变更

### 产品定位变化
- 从"视频发现+个人管理"工具 → 纯"个人内容管理"工具
- 更加轻量和聚焦，但失去内容发现能力
