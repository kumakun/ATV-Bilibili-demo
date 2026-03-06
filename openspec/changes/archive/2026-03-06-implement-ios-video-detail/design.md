## 上下文

iOS项目正在从tvOS迁移功能，需要实现视频详情页。tvOS使用UIKit + UIViewController架构，而iOS端使用SwiftUI + @Observable架构。两个项目不共享代码，iOS需要完全重新实现。

当前iOS项目已有：
- SwiftUI-based的View架构（FollowView, FavoriteView等）
- @Observable的ViewModel模式
- ApiRequestBridge用于API调用
- WebRequestBridge用于网络请求
- 基础UI组件（VideoCard, ErrorView, LoadingView等）

tvOS端VideoDetailViewController提供了功能参考：
- 视频信息展示（标题、UP主、封面、统计数据）
- 视频播放器集成（AVPlayer + 弹幕）
- 互动功能（点赞、投币、收藏、关注）
- 分P选集和合集支持
- 相关视频推荐

## 目标 / 非目标

**目标：**
- 实现功能完整的iOS视频详情页，包括信息展示和播放能力
- 使用SwiftUI构建符合iOS设计规范的UI
- 使用@Observable实现状态管理
- 支持从现有feed流（关注、收藏等）导航到详情页
- 实现核心互动功能（点赞、投币、收藏、关注）
- 支持视频分P和合集
- 集成AVPlayer进行视频播放

**非目标：**
- 弹幕功能（一期不实现，后续迭代）
- DLNA/AirPlay投屏（后续迭代）
- 评论区（后续迭代）
- 视频下载（后续迭代）
- 与tvOS代码共享（两个项目独立）

## 决策

### 1. 架构模式：MVVM with SwiftUI + @Observable

**选择：** 使用SwiftUI + @Observable的MVVM架构

**理由：**
- 与现有iOS项目架构一致（FollowViewModel, FavoriteViewModel等）
- @Observable提供现代化的状态管理，自动UI更新
- SwiftUI declarative UI降低复杂度
- 易于测试和维护

**替代方案：**
- UIKit + UIViewController（与tvOS一致）：被拒绝，因为iOS项目已全面使用SwiftUI
- Combine + ObservableObject：被拒绝，@Observable是更现代的Swift特性

### 2. 组件结构

**选择：** 将视频详情页拆分为多个子组件

组件划分：
```
VideoDetailView (主容器)
├── VideoPlayerView (视频播放器)
├── VideoInfoSection (标题、UP主、统计)
├── VideoDescriptionSection (简介)
├── VideoActionBar (点赞、投币、收藏等)
├── VideoEpisodesSection (分P选集)
└── RelatedVideosSection (相关推荐)
```

**理由：**
- 单一职责，每个组件负责一块UI
- 易于复用和测试
- 便于后续扩展和维护
- SwiftUI的组合特性天然支持这种结构

### 3. 状态管理

**选择：** 使用VideoDetailViewModel统一管理状态

ViewModel负责：
- 视频详情数据加载
- 播放状态管理
- 用户互动操作（点赞、投币等）
- 分P切换逻辑
- 错误处理

**理由：**
- 集中化状态管理，避免状态分散
- 便于处理复杂的异步操作
- 与现有ViewModel模式一致

### 4. 网络层复用

**选择：** 创建iOS版本的API请求方法，参考tvOS但不共享代码

在`BilibiliLive-iOS/Models/`下创建：
- `VideoDetailModels.swift`：数据模型
- 在现有的`WebRequestBridge`或`ApiRequestBridge`中添加方法

**理由：**
- 两个项目要求不共享代码
- iOS可能需要不同的数据结构适配SwiftUI
- API调用逻辑相对简单，重新实现成本可控

**替代方案：**
- 共享网络层代码：被拒绝，违反项目要求

### 5. 视频播放方案

**选择：** 使用AVKit的VideoPlayer（SwiftUI原生）

```swift
VideoPlayer(player: AVPlayer(url: videoURL))
```

**理由：**
- SwiftUI原生组件，集成简单
- 自带播放控件，符合iOS标准
- 支持画中画等iOS特性

**替代方案：**
- 自定义AVPlayerViewController：过度工程，SwiftUI原生方案已足够
- 第三方播放器：增加依赖复杂度

### 6. 导航方式

**选择：** 使用SwiftUI NavigationLink进行页面导航

从feed流跳转到详情页：
```swift
NavigationLink(destination: VideoDetailView(aid: video.aid)) {
    VideoCard(video: video)
}
```

**理由：**
- SwiftUI标准导航方式
- 自动处理导航栏和返回
- 支持深度链接

## 风险 / 权衡

### 风险1：视频播放性能和体验

**风险：** SwiftUI的VideoPlayer功能相对简单，可能无法满足所有需求（如弹幕、倍速、画质切换）

**缓解措施：**
- 一期使用VideoPlayer满足基本播放需求
- 后续可以封装AVPlayer + 自定义控件实现高级功能
- 参考tvOS的BVideoPlayPlugin实现画质切换

### 风险2：复杂状态管理

**风险：** 视频详情页状态复杂（播放状态、点赞状态、分P状态等），可能导致ViewModel过于庞大

**缓解措施：**
- 将部分状态逻辑抽离到独立的Service或Manager
- 使用子ViewModel处理独立功能（如EpisodesViewModel）
- 合理使用Computed Properties减少冗余状态

### 风险3：API数据结构差异

**风险：** tvOS和iOS可能需要不同的数据结构，完全重写可能遗漏字段

**缓解措施：**
- 仔细参考tvOS的VideoDetail模型
- 创建完整的单元测试验证数据解析
- 逐个功能验证，确保数据完整性

### 风险4：开发工作量

**风险：** 完全重新实现功能，工作量较大

**缓解措施：**
- 分阶段实现，优先核心功能（信息展示+播放）
- 互动功能（点赞、投币等）可以后续迭代
- 复用现有UI组件降低开发成本

## 迁移计划

不适用（这是新功能，不涉及迁移）

## 开放问题

1. **弹幕实现时机？** - 一期不实现，但需要预留接口
2. **视频缓存策略？** - 是否需要缓存视频详情数据？
3. **横屏播放支持？** - iOS是否需要支持横屏全屏播放？
4. **iPad适配？** - 是否需要针对iPad优化布局？
