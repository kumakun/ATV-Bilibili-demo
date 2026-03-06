## 为什么

iOS平台目前缺少视频详情页功能，用户在浏览视频feed流（关注、推荐、收藏等）时无法查看视频详细信息和播放视频。tvOS平台已有成熟的VideoDetailViewController实现，需要为iOS平台实现类似功能，使用SwiftUI构建原生的iOS视频详情体验。

## 变更内容

- **新增** iOS平台的视频详情页View和ViewModel
- **新增** 视频播放支持（集成AVPlayer）
- **新增** 视频信息展示（标题、UP主、统计数据、简介等）
- **新增** 互动功能（点赞、投币、收藏、关注UP主）
- **新增** 视频分P选集支持
- **新增** 相关视频推荐展示
- **新增** 从现有feed流（关注、收藏等）跳转到视频详情页

## 功能 (Capabilities)

### 新增功能
- `ios-video-detail-view`: iOS平台视频详情页面展示，包括视频信息、UP主信息、统计数据、简介、操作按钮等UI组件
- `ios-video-player`: iOS平台视频播放器集成，支持画质选择、播放控制、弹幕等功能
- `ios-video-interaction`: 视频互动功能，包括点赞、投币、收藏、分享、关注UP主等操作
- `ios-video-episodes`: 视频分P和合集支持，展示和切换不同集数
- `ios-video-navigation`: 从各个feed流入口（关注、收藏、动态等）导航到视频详情页

### 修改功能
无

## 影响

**受影响的代码**：
- `BilibiliLive-iOS/Views/` - 需要创建新的视频详情页相关View
- `BilibiliLive-iOS/ViewModels/` - 需要创建VideoDetailViewModel
- `BilibiliLive-iOS/Models/` - 可能需要添加视频详情相关数据模型
- `BilibiliLive-iOS/Views/FollowView.swift` - 需要添加导航到视频详情页
- `BilibiliLive-iOS/Views/FavoriteView.swift` - 需要添加导航到视频详情页

**依赖的API**：
- 视频详情API（已在tvOS中使用，需要在iOS端重新实现请求层）
- 视频播放URL API
- 点赞、投币、收藏等互动API
- UP主关注API

**技术栈**：
- SwiftUI用于UI构建
- @Observable框架用于状态管理
- AVFoundation用于视频播放
- Combine用于异步数据流处理
