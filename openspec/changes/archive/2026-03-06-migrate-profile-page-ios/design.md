## 上下文

iOS 版本的"我的"页面（ProfileView）当前只有静态 UI 占位符，缺少功能实现。tvOS 版本已经实现了完整的个人中心功能，使用 UIKit 和传统的 ViewController 架构。iOS 版本需要使用 SwiftUI 和现代化的 @Observable 框架重新实现这些功能，不能共享 tvOS 的代码。

### 当前状态
- iOS 端已有基础的架构：AccountManagerIOS、ApiRequestBridge、WebRequestBridge
- ProfileView 存在但仅有静态 UI
- 已有登录流程和 QR 码登录功能
- 数据层（API 请求）需要在 iOS 侧重新实现

### 约束
- 必须使用 SwiftUI 和 @Observable 框架
- 不能与 tvOS 共享代码，需要独立实现
- 需要保持 API 调用逻辑与 tvOS 一致
- 必须适配 iOS 移动设备的交互模式

## 目标 / 非目标

**目标：**
- 实现完整的个人中心功能，提供与 tvOS 版本一致的用户体验
- 使用 SwiftUI 现代化架构，充分利用 @Observable 框架进行状态管理
- 为每个功能创建独立的 View 和 ViewModel，保持代码模块化
- 实现响应式 UI，自动响应账号状态变化
- 适配 iOS 移动设备的导航和布局模式

**非目标：**
- 不直接复用 tvOS 的代码或组件
- 不实现新的 API 端点（使用现有 B 站 API）
- 不改变 tvOS 的现有功能或行为
- 不在此阶段实现视频播放功能优化（使用现有播放器）

## 决策

### 决策 1: 使用 MVVM 架构模式配合 @Observable

**理由：**
- @Observable 是 Swift 5.9+ 的现代状态管理方案，比 ObservableObject 更简洁高效
- MVVM 模式将业务逻辑与 UI 分离，便于测试和维护
- ViewModel 层可以封装 API 请求和数据转换逻辑

**替代方案：**
- 使用传统的 ObservableObject + @Published：更冗长，需要更多样板代码
- 直接在 View 中处理数据：违反关注点分离原则，难以测试
- 使用 Redux/TCA：过于复杂，对于这个规模的功能不必要

**实现要点：**
```swift
@Observable
final class ProfileViewModel {
    var userProfile: UserProfile?
    var isLoading: Bool = false
    
    func loadProfile() async {
        // 通过 AccountManagerIOS 和 ApiRequestBridge 获取数据
    }
}
```

### 决策 2: 为每个功能创建独立的 View 和 ViewModel

**理由：**
- 关注点分离，每个功能模块独立开发和测试
- 便于代码复用和维护
- 符合 SwiftUI 的组件化思想
- 可以按功能优先级分阶段实现

**文件组织结构：**
```
BilibiliLive-iOS/
├── Views/
│   ├── ProfileView.swift (主入口)
│   ├── Profile/
│   │   ├── UserProfileCard.swift
│   │   ├── FunctionListView.swift
│   │   ├── FollowUpsView.swift
│   │   ├── FollowBangumiView.swift
│   │   ├── WatchHistoryView.swift
│   │   ├── WatchLaterView.swift
│   │   ├── WeeklyWatchView.swift
│   │   └── AccountSwitcherView.swift
├── ViewModels/
│   ├── ProfileViewModel.swift
│   ├── FollowUpsViewModel.swift
│   ├── FollowBangumiViewModel.swift
│   ├── WatchHistoryViewModel.swift
│   ├── WatchLaterViewModel.swift
│   ├── WeeklyWatchViewModel.swift
│   └── AccountSwitcherViewModel.swift
└── Models/
    └── ProfileModels.swift (数据模型)
```

### 决策 3: 使用 NavigationStack 进行页面导航

**理由：**
- NavigationStack 是 iOS 16+ 的推荐导航方式，支持深层链接和状态恢复
- 类型安全的路由管理
- 支持编程式导航和声明式导航

**替代方案：**
- 使用传统 NavigationView：已被弃用
- 使用 sheet/fullScreenCover：不适合列表式导航
- 自定义导航系统：过度工程化

**实现要点：**
```swift
enum ProfileRoute: Hashable {
    case followUps
    case followBangumi
    case watchHistory
    case watchLater
    case weeklyWatch
}

struct ProfileView: View {
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            // 主界面
        }
        .navigationDestination(for: ProfileRoute.self) { route in
            // 路由到对应页面
        }
    }
}
```

### 决策 4: 扩展 ApiRequestBridge 和 WebRequestBridge

**理由：**
- iOS 端已有 Bridge 架构用于调用 tvOS 的 API 层
- 保持 API 逻辑一致性，复用数据模型定义
- 避免重复实现网络请求逻辑

**实现方式：**
- 为每个新功能在 Bridge 中添加对应的方法
- 将 tvOS 的 WebRequest 方法在 iOS 侧重新实现
- 使用 Swift Concurrency (async/await) 替代回调

**示例：**
```swift
extension ApiRequestBridge {
    static func requestFollowingUps(page: Int) async throws -> [FollowingUser] {
        // 调用 WebRequestBridge 获取数据
    }
    
    static func requestWatchHistory() async throws -> [HistoryItem] {
        // 实现历史记录请求
    }
}
```

### 决策 5: 使用 @Observable 统一管理账号状态

**理由：**
- AccountManagerIOS 已使用 @Observable，保持架构一致
- 所有 View 可以自动响应账号变化（登录/登出/切换）
- 避免手动管理通知监听

**实现要点：**
- 所有需要账号信息的 ViewModel 依赖 AccountManagerIOS.shared
- View 自动响应 AccountManagerIOS 的状态变化
- 登出/切换账号时自动刷新 UI

### 决策 6: 使用 AsyncImage 和 CachedAsyncImage 加载图片

**理由：**
- SwiftUI 原生支持，无需引入第三方库
- 自动处理加载状态和错误
- 支持占位图和重试

**替代方案：**
- 使用 Kingfisher（tvOS 使用）：iOS 不共享代码，避免引入
- 自定义图片加载器：不必要的复杂度

**实现方式：**
- 优先使用 SwiftUI 原生 AsyncImage
- 如果需要缓存优化，实现简单的 CachedAsyncImage 组件

## 风险 / 权衡

### 风险 1: API 数据模型与 tvOS 不一致
**缓解措施：**
- 参考 tvOS 的数据模型定义，在 iOS 侧创建对应的 Codable 结构
- 使用 JSON 解析测试确保数据结构正确
- 在开发初期先实现 API 层，验证数据正确性

### 风险 2: @Observable 框架的学习曲线
**缓解措施：**
- @Observable 语法简单，已在 AccountManagerIOS 中使用
- 参考现有代码模式进行实现
- 遇到问题可回退到 ObservableObject

### 风险 3: 分页加载和列表性能
**权衡：**
- 使用 LazyVStack/LazyVGrid 优化列表性能
- 实现分页加载避免一次性加载大量数据
- 可能需要调整列表布局以适配移动设备屏幕

### 风险 4: 导航状态管理复杂度
**缓解措施：**
- 使用 NavigationStack 的类型安全路由
- 避免深层嵌套导航
- 使用 @Environment 在视图树中传递导航状态

### 风险 5: 账号切换时的数据刷新
**权衡：**
- AccountManagerIOS 已支持账号切换通知
- ViewModel 需要监听账号变化并重新加载数据
- 可能导致短暂的加载状态，需要优化用户体验

### 风险 6: 移动设备布局适配
**缓解措施：**
- 使用 SwiftUI 的自适应布局（VStack/HStack）
- 针对 iPhone 和 iPad 使用不同的列数
- 测试不同屏幕尺寸的显示效果

## 迁移计划

### 第 1 阶段：重构 ProfileView 主页面
1. 实现 ProfileViewModel 集成 AccountManagerIOS
2. 重构 UserInfoCard 显示真实用户数据
3. 实现 FunctionListView 的导航功能

### 第 2 阶段：实现核心列表功能
1. 实现关注 UP 主列表（FollowUpsView + ViewModel）
2. 实现历史记录（WatchHistoryView + ViewModel）
3. 实现稍后再看（WatchLaterView + ViewModel）
4. 扩展 ApiRequestBridge 支持这些 API 调用

### 第 3 阶段：实现追番和推荐功能
1. 实现追番追剧（FollowBangumiView + ViewModel）
2. 实现每周必看（WeeklyWatchView + ViewModel）

### 第 4 阶段：实现账号管理功能
1. 实现账号切换界面（AccountSwitcherView）
2. 实现登出流程和确认对话框
3. 集成到 ProfileView 功能列表

### 回滚策略
- 每个阶段独立完成，可以逐步发布
- 保留原有静态 ProfileView 作为后备
- 使用 feature flag 控制新功能的启用

## 开放问题

1. **图片缓存策略**：是否需要实现自定义图片缓存，还是依赖系统 URLCache？
   - 建议：先使用系统 URLCache，如果性能不足再优化

2. **视频播放页面导航**：点击视频后如何导航到播放页面？需要与现有播放器集成
   - 建议：使用现有的 VideoDetailViewController 桥接（如果有）或创建 SwiftUI 版本

3. **删除操作的确认方式**：使用 Alert 还是 ConfirmationDialog？
   - 建议：使用 ConfirmationDialog，更符合 iOS 设计规范

4. **错误处理和重试机制**：统一的错误提示和重试 UI 如何设计？
   - 建议：创建通用的 ErrorView 组件，支持错误信息展示和重试按钮

5. **下拉刷新支持**：哪些列表需要支持下拉刷新？
   - 建议：关注列表、历史记录支持；每周必看、稍后再看按需决定
