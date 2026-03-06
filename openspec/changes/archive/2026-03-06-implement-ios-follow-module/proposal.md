## 为什么

iOS 端目前还没有实现关注模块功能（显示关注的 UP 主动态）。tvOS 端已经实现了完整的关注页面（FollowsViewController），可以展示关注 UP 的动态视频流，支持刷新和分页加载。为了让 iOS 用户也能方便地浏览关注内容，需要将此功能迁移到 iOS 端。

## 变更内容

- **新增**：iOS 关注页面，展示用户关注 UP 主的动态视频流
- **新增**：动态 Feed 数据模型和 API 请求桥接
- **新增**：FollowViewModel 处理数据加载和分页逻辑
- **新增**：FollowView SwiftUI 界面，支持筛选（全部/视频/直播）
- **新增**：支持下拉刷新和滚动自动加载更多
- **新增**：支持点击视频卡片进入详情页

## 功能 (Capabilities)

### 新增功能

- `follow-feed`: 关注页面的动态 Feed 功能，展示用户关注 UP 主发布的视频动态，支持筛选、刷新和分页加载

### 修改功能

无

## 影响

- **新增文件**：
  - `BilibiliLive-iOS/Views/FollowView.swift` - 关注页面主视图
  - `BilibiliLive-iOS/ViewModels/FollowViewModel.swift` - 关注页面视图模型
  - `BilibiliLive-iOS/Models/FollowModels.swift` - 动态 Feed 数据模型
  
- **修改文件**：
  - `BilibiliLive-iOS/Models/ApiRequestBridge.swift` - 添加请求关注动态的 API 方法
  - `BilibiliLive-iOS/MainTabView.swift` - 已有 FollowView 占位，需要替换为实际实现

- **依赖**：
  - 需要用户已登录状态
  - 依赖现有的 ApiRequest 和 WebRequest 框架
