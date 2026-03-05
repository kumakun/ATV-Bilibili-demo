## 为什么

当前 iOS "我的"模块的界面设计主要针对 iPhone 竖屏场景，在 iPad 上未充分利用大屏幕空间。"关注 粉丝 获赞"统计数据显示在独立的卡片区域，占用了宝贵的垂直空间，且信息价值相对较低。iPad 用户需要更高效的交互方式来访问各个功能模块，SplitView 交互方式能够让用户在左侧快速切换功能，右侧实时查看内容，提供更好的浏览体验。

## 变更内容

1. **移除统计数据展示**：删除"关注 粉丝 获赞"这个独立的 section（UserStatsView 组件），在用户信息卡片中也不再显示这些统计数字
2. **iPad SplitView 交互**：在 iPad 上实现 SplitView 布局，左侧显示功能列表（关注UP、追番追剧、历史记录等），右侧显示对应的详细内容页面
3. **适配不同设备**：iPhone 保持现有的 NavigationStack 交互方式（push 导航），iPad 使用 SplitView 交互方式
4. **优化布局**：精简页面结构，移除不必要的数据展示，让核心功能更突出

## 功能 (Capabilities)

### 新增功能
- `ipad-profile-splitview`: iPad 个人中心页面的 SplitView 交互实现，包括侧边栏功能列表和详情页显示区域的联动

### 修改功能
- `user-profile-info`: 移除"关注 粉丝 获赞"统计数据的显示需求，简化用户信息展示

## 影响

**视图层影响**：
- `BilibiliLive-iOS/Views/ProfileView.swift`：主视图结构调整，移除 UserStatsView 组件，添加 iPad SplitView 支持
- 需要删除或重构 `UserStatsView` 组件
- 需要新增或调整功能列表在 SplitView 侧边栏中的展示方式

**ViewModel 影响**：
- `BilibiliLive-iOS/ViewModels/ProfileViewModel.swift`：移除关注数、粉丝数、获赞数相关的属性和逻辑

**设备适配**：
- 需要添加设备类型判断逻辑（iPhone vs iPad）
- 不同设备使用不同的导航方式和布局结构

**用户体验**：
- iPad 用户获得更高效的多任务浏览体验
- 简化的界面减少信息过载，让用户更关注核心功能
