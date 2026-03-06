## 上下文

当前 iOS 应用已有基本框架，包括账号管理、API 请求桥接等基础设施。tvOS 平台已有完整的收藏模块实现，使用 UIKit 和 UICollectionView。现需要将此功能迁移到 iOS 平台，使用 SwiftUI 重新实现，不共享代码。

**现有基础设施**：
- AccountManagerIOS：账号管理和登录状态
- WebRequestBridge：网络请求桥接层
- 已有的 ViewModel 模式（如 FollowBangumiViewModel）
- SwiftUI 视图结构

**tvOS 参考实现**：
- `FavoriteViewController`：使用 CategoryViewController 展示收藏夹列表
- `FavoriteVideoContentViewController`：使用 StandardVideoCollectionViewController 展示内容
- WebRequest API：已有的收藏相关 API 方法

## 目标 / 非目标

**目标：**
- 实现完整的收藏模块，包括收藏夹列表和内容展示
- 使用 @Observable 和 SwiftUI 实现响应式状态管理
- 支持分页加载和下拉刷新
- 提供良好的加载和错误状态反馈
- 支持 iPhone 和 iPad 的自适应布局
- 支持跳转到视频详情页（后续功能，本次仅预留接口）

**非目标：**
- 不实现收藏夹的创建、编辑、删除功能（使用 B站网页端管理）
- 不实现视频的收藏/取消收藏操作（在视频详情页实现）
- 不实现收藏夹的排序功能
- 不与 tvOS 共享代码

## 决策

### 1. 架构模式：MVVM with @Observable

**决策**：使用 MVVM 架构，ViewModel 使用 @Observable 宏。

**理由**：
- 与现有代码风格一致（参考 FollowBangumiViewModel）
- @Observable 提供自动的依赖跟踪和 UI 更新
- 比 @Published + ObservableObject 更简洁
- 支持 MainActor 隔离保证线程安全

**替代方案**：
- ❌ @Published + ObservableObject：旧的方式，代码更冗长
- ❌ 直接在 View 中管理状态：违反关注点分离原则

### 2. 数据模型：独立定义 vs 共享

**决策**：在 iOS 项目中独立定义数据模型（FavListData, FavData），不与 tvOS 共享。

**理由**：
- 项目要求不共享代码
- iOS 可能需要不同的字段或格式
- 保持两个平台的独立性和可维护性

**实现**：
- 在 `BilibiliLive-iOS/Models/FavoriteModels.swift` 定义模型
- 模型结构参考 tvOS 但独立定义

### 3. API 请求：桥接模式

**决策**：在 WebRequestBridge 中添加收藏相关的请求方法，内部调用 tvOS 项目的 WebRequest。

**理由**：
- 复用现有的 API 实现和认证逻辑
- 保持 iOS 代码的清晰边界
- 便于后续完全独立实现

**方法**：
```swift
// 在 WebRequestBridge 中添加
static func requestFavVideosList() async throws -> [FavListDataIOS]
static func requestFavVideos(mediaId: String, page: Int) async throws -> [FavDataIOS]
static func requestFavFolderCollectedList() async throws -> [FavListDataIOS]
```

### 4. UI 结构：双层导航

**决策**：
- 第一层：FavoriteView 展示收藏夹列表
- 第二层：FavoriteFolderView 展示收藏夹内容（视频列表）

**理由**：
- 符合用户心智模型（文件夹 → 内容）
- 与 tvOS 的 CategoryViewController 结构对应
- 支持清晰的导航层级

**实现**：
- FavoriteView + FavoriteViewModel：管理收藏夹列表
- FavoriteFolderView + FavoriteFolderViewModel：管理单个收藏夹内容

### 5. 分页策略：按需加载

**决策**：
- 收藏夹列表：一次性加载全部（通常不超过 100 个）
- 收藏夹内容：分页加载，每页 20 条

**理由**：
- 收藏夹数量通常不多，一次加载体验更好
- 视频列表可能很长，分页减少加载时间和内存占用
- 与 B站 API 的分页参数对应

**实现**：
```swift
// ViewModel 中
var currentPage = 1
var hasMore = true
func loadMore() async { ... }
```

### 6. 状态管理：枚举状态机

**决策**：使用枚举管理加载状态。

```swift
enum LoadingState {
    case idle
    case loading
    case loaded
    case error(String)
}
```

**理由**：
- 明确的状态转换，避免状态混乱
- 便于 UI 根据状态显示不同内容
- 与 Swift 的类型安全特性契合

### 7. 视图组件：可复用卡片

**决策**：将收藏夹卡片和视频卡片封装为独立的 View 组件。

**组件**：
- `FavoriteFolderCard`：收藏夹卡片（图标、名称、数量）
- `VideoCard`：视频卡片（封面、标题、UP主、数据）

**理由**：
- 组件复用（视频卡片可在多处使用）
- 便于维护和测试
- 符合 SwiftUI 的组件化思想

## 风险 / 权衡

### 风险 1：API 兼容性
**风险**：B站 API 可能变更，导致数据解析失败。
**缓解**：
- 使用 optional 字段处理缺失数据
- 添加错误处理和降级展示
- 参考 tvOS 的成熟实现

### 风险 2：分页加载性能
**风险**：大量视频加载可能导致内存占用过高。
**缓解**：
- 使用 LazyVStack 延迟渲染
- 限制缓存的图片数量
- 实现适当的内存警告处理

### 风险 3：用户未登录
**风险**：未登录用户无法访问收藏功能。
**缓解**：
- 检查 AccountManagerIOS.shared.isLoggedIn
- 显示登录引导界面
- 提供清晰的错误提示

### 权衡 1：功能完整性 vs 开发速度
**权衡**：暂不实现收藏夹管理功能，专注于展示。
**影响**：用户需要到网页端管理收藏夹。
**理由**：展示功能是核心需求，管理功能可后续迭代。

### 权衡 2：代码复用 vs 平台独立
**权衡**：不与 tvOS 共享代码，增加维护成本。
**影响**：修改需要在两个平台同步。
**理由**：项目要求，保持平台特性和独立性。

## 迁移计划

### 阶段 1：数据层（Models + API Bridge）
1. 创建 `FavoriteModels.swift` 定义数据模型
2. 在 `WebRequestBridge.swift` 添加 API 方法
3. 编写单元测试验证数据解析

### 阶段 2：ViewModel 层
1. 创建 `FavoriteViewModel.swift`
2. 创建 `FavoriteFolderViewModel.swift`
3. 实现加载逻辑和状态管理

### 阶段 3：UI 层
1. 重构 `FavoriteView.swift` 连接 ViewModel
2. 创建 `FavoriteFolderView.swift` 展示内容
3. 创建可复用组件（FavoriteFolderCard, VideoCard）

### 阶段 4：测试和优化
1. 在模拟器和真机测试
2. 处理边界情况（空列表、网络错误等）
3. 优化性能和用户体验

### 回滚策略
- 保留原有的 FavoriteView 静态占位符
- 如遇严重问题可通过条件编译临时回退
- 使用 git 分支管理，便于快速回滚

## 开放问题

1. **视频详情页跳转**：目前 iOS 项目可能还没有实现视频详情页，需要确认跳转接口。
   - 解决方案：预留跳转方法，等详情页实现后再连接。

2. **图片加载库**：需要确认使用哪个图片加载库（Kingfisher 或 AsyncImage）。
   - 倾向：优先使用原生 AsyncImage，如有性能问题再考虑 Kingfisher。

3. **订阅收藏夹的处理**：tvOS 中区分自建收藏夹和订阅收藏夹，需要确认 UI 如何区分。
   - 建议：使用不同的图标或标签区分。
