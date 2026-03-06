## 上下文

iOS 端的关注页面目前只有一个占位实现（FollowView.swift），展示的是静态的 mock 数据。tvOS 端已经实现了完整的关注动态流功能（FollowsViewController），使用哔哩哔哩动态 Feed API 获取关注 UP 主的最新动态视频，支持分页加载和刷新。

**当前状态**：
- iOS 端已有 FollowView 占位，使用静态数据
- tvOS 端的 FollowsViewController 使用 `https://api.bilibili.com/x/polymer/web-dynamic/v1/feed/all` API
- tvOS 端的数据模型为 `DynamicFeedData`，解析动态 JSON 结构
- 已有完整的 API 请求基础设施（ApiRequest、WebRequest）
- iOS 端已实现关注 UP 主列表（FollowUpsView）和追番追剧（FollowBangumiView）

**约束**：
- 使用 SwiftUI + @Observable 框架
- iOS 代码独立，不与 tvOS 共享代码
- 需要适配 iPhone 和 iPad 不同屏幕尺寸
- 遵循现有的 iOS 端代码结构（Views、ViewModels、Models）

## 目标 / 非目标

**目标：**
- 在 iOS 端实现完整的关注动态 Feed 功能
- 展示关注 UP 主的最新视频动态（封面、标题、UP 主信息、发布时间、播放数据）
- 支持下拉刷新和滚动到底自动加载更多
- 支持筛选器切换（全部/视频/直播）
- 支持点击视频卡片导航到视频详情页
- 实现优雅的加载状态和错误处理
- 适配 iOS 设备的界面布局

**非目标：**
- 不实现直播内容的展示（仅保留筛选器 UI）
- 不实现动态的点赞、评论等互动功能
- 不实现关注 UP 主管理（已有 FollowUpsView）
- 不支持动态内容的图文、转发等非视频类型

## 决策

### 决策 1: 复用 tvOS 的 API 和数据结构，但使用 iOS 的命名约定

**理由**：tvOS 端已验证了 API 的可用性和数据结构的正确性。为了快速实现功能，我们将参考 tvOS 的实现方式，但为 iOS 端重新编写代码。

**方案**：
- 参考 tvOS 的 `WebRequest.requestFollowsFeed` API 调用方式
- 参考 tvOS 的 `DynamicFeedData` 数据模型结构
- 在 iOS 端创建新的 `FollowModels.swift`，定义 Swift Codable 模型
- 在 `WebRequestBridge.swift` 中添加 `requestFollowsFeed` 静态方法

**替代方案**：
- ❌ 直接共享 tvOS 代码：违反项目约束，iOS 需独立代码
- ❌ 使用不同的 API：没有必要，现有 API 已经满足需求

### 决策 2: 使用 @Observable + async/await 实现 ViewModel

**理由**：与现有的 iOS 代码风格保持一致（参考 FollowUpsViewModel、FollowBangumiViewModel），使用现代的 Swift 并发模型。

**方案**：
- 创建 `FollowViewModel` 使用 `@Observable` 宏
- 使用 `@MainActor` 确保 UI 更新在主线程
- 使用 `async/await` 处理网络请求
- 实现 `loadInitial()`, `refresh()`, `loadMore()` 方法
- 管理状态：`feeds`, `isLoading`, `isLoadingMore`, `errorMessage`, `hasMore`

**替代方案**：
- ❌ 使用 Combine：增加复杂度，与现有代码风格不一致
- ❌ 使用 ObservableObject：@Observable 是 iOS 17+ 的现代方案

### 决策 3: 保持简单的 List 布局，暂不实现直播筛选逻辑

**理由**：tvOS 端目前只展示视频类型的动态，直播内容的数据结构和展示方式需要额外研究。为了快速实现 MVP，先保留筛选器 UI，但所有筛选选项都显示相同的视频动态。

**方案**：
- 创建 SwiftUI 的 Picker 筛选器（全部/视频/直播）
- 所有选项都调用相同的 API 和数据
- UI 上保留扩展空间，后续可以添加直播逻辑

**替代方案**：
- ❌ 完全移除筛选器：用户期望有筛选功能
- ❌ 实现完整的直播筛选：需要额外的 API 研究和开发时间

### 决策 4: 使用 offset-based 分页，而非 page-based

**理由**：tvOS 端使用的是 offset-based 分页（`lastOffset` 字符串），这是哔哩哔哩动态 Feed API 的设计方式，可以更精确地定位下一批数据。

**方案**：
- ViewModel 维护 `lastOffset: String` 状态
- 初始加载时 offset 为空字符串
- 每次请求后更新 offset 为响应中的 `next_offset`
- 下次加载时传入上次的 offset

**替代方案**：
- ❌ 使用传统的 page 数字：不适合哔哩哔哩的动态流 API

### 决策 5: 实现防抖机制，避免重复请求

**理由**：参考 FollowUpsViewModel 的实现，使用状态标志防止重复加载。

**方案**：
- 使用 `isLoading` 和 `isLoadingMore` 标志
- 在请求开始时检查标志，如果正在加载则直接返回
- 在请求结束后重置标志

## 风险 / 权衡

**风险 1: 动态内容类型复杂，可能包含非视频内容**
- **缓解措施**：参考 tvOS 的过滤逻辑，只展示包含视频内容的动态（archive 或 pgc 类型）

**风险 2: API 返回的数据可能不稳定**
- **缓解措施**：实现完善的错误处理和可选值解析，使用 Swift Codable 的默认值

**风险 3: 视频详情页导航可能需要额外参数**
- **缓解措施**：参考现有的视频详情页实现，传递必要的 aid、cid、epid 参数

**权衡 1: 不支持图文、转发等非视频动态**
- **影响**：用户看到的动态数量可能少于 Web 端
- **理由**：聚焦视频内容，简化实现复杂度

**权衡 2: 暂不实现直播内容**
- **影响**：筛选器目前是装饰性的
- **理由**：优先实现核心功能，后续迭代可以添加

## 迁移计划

不涉及数据迁移或破坏性变更。这是一个纯新增功能。

**部署步骤**：
1. 创建数据模型和 API 桥接
2. 创建 ViewModel
3. 实现 FollowView UI
4. 测试加载、刷新、分页功能
5. 测试点击跳转到详情页
6. 进行 UI 调整和错误处理完善

**回滚策略**：
- 如果出现问题，FollowView 可以回退到当前的占位实现
- MainTabView 不需要修改（已经引用了 FollowView）

## 开放问题

1. **是否需要实现动态内容的缓存？**
   - 当前方案：不实现缓存，每次都从网络加载
   - 待定：如果用户反馈频繁加载，可以考虑添加内存缓存

2. **视频详情页的导航方式？**
   - 当前方案：参考 tvOS 的 VideoDetailViewController 和 iOS 端现有的导航模式
   - 待定：是否需要创建 iOS 版本的 VideoDetailView
