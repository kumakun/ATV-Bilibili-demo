## 1. 数据模型层

- [x] 1.1 创建 FavoriteModels.swift 文件在 BilibiliLive-iOS/Models/ 目录
- [x] 1.2 定义 FavListDataIOS 结构体，包含 id、title、mediaCount、isCreatedBySelf、mid 字段
- [x] 1.3 为 FavListDataIOS 实现 Codable、Identifiable、Hashable 协议
- [x] 1.4 定义 FavDataIOS 结构体，包含 id、title、cover、intro、duration、upper、cnt_info、ogv 字段
- [x] 1.5 为 FavDataIOS 实现 Codable、Identifiable、Hashable 协议
- [x] 1.6 为 FavDataIOS 添加 durationText 计算属性，格式化时长为"mm:ss"或"hh:mm:ss"
- [x] 1.7 添加播放数格式化扩展方法（如"1.2万"）

## 2. API 桥接层

- [x] 2.1 在 WebRequestBridge.swift 中添加 requestFavVideosList() async throws -> [FavListDataIOS] 方法
- [x] 2.2 在 WebRequestBridge.swift 中添加 requestFavVideos(mediaId: String, page: Int) async throws -> [FavDataIOS] 方法
- [x] 2.3 在 WebRequestBridge.swift 中添加 requestFavFolderCollectedList() async throws -> [FavListDataIOS] 方法
- [x] 2.4 在 WebRequestBridge.swift 中添加 requestFavSeason(seasonId: String, page: Int) async throws -> [FavDataIOS] 方法
- [x] 2.5 实现从 tvOS 模型到 iOS 模型的数据转换逻辑
- [x] 2.6 添加错误处理和类型转换

## 3. FavoriteViewModel

- [x] 3.1 创建 FavoriteViewModel.swift 文件在 BilibiliLive-iOS/ViewModels/ 目录
- [x] 3.2 定义 FavoriteViewModel 类，标记 @Observable 和 @MainActor
- [x] 3.3 添加状态属性：folders: [FavListDataIOS]、isLoading: Bool、errorMessage: String?
- [x] 3.4 实现 loadFolders() async 方法，调用两个 API 并合并结果
- [x] 3.5 为自建收藏夹设置 isCreatedBySelf = true
- [x] 3.6 实现 refresh() async 方法，清空数据并重新加载
- [x] 3.7 添加登录状态检查逻辑
- [x] 3.8 实现错误处理，将 API 错误转换为友好提示

## 4. FavoriteFolderViewModel

- [x] 4.1 创建 FavoriteFolderViewModel.swift 文件在 BilibiliLive-iOS/ViewModels/ 目录
- [x] 4.2 定义 FavoriteFolderViewModel 类，标记 @Observable 和 @MainActor
- [x] 4.3 添加状态属性：folder、videos: [FavDataIOS]、currentPage、hasMore、isLoading、isLoadingMore、errorMessage
- [x] 4.4 实现初始化方法，接受 folder: FavListDataIOS 参数
- [x] 4.5 实现 loadVideos() async 方法，加载第一页数据
- [x] 4.6 根据 folder.isCreatedBySelf 判断调用 requestFavVideos 或 requestFavSeason
- [x] 4.7 实现 loadMore() async 方法，检查 hasMore 并加载下一页
- [x] 4.8 实现 refresh() async 方法，重置分页状态并重新加载
- [x] 4.9 实现分页逻辑：每页20条，根据返回数据数量判断 hasMore
- [x] 4.10 添加错误处理逻辑

## 5. 可复用 UI 组件

- [x] 5.1 创建 FavoriteFolderCard.swift 文件在 BilibiliLive-iOS/Views/Components/ 目录（如不存在则创建）
- [x] 5.2 实现 FavoriteFolderCard 组件，展示收藏夹图标、名称和数量
- [x] 5.3 为自建和订阅收藏夹设置不同的视觉样式（图标颜色或标签）
- [x] 5.4 创建 VideoCard.swift 文件在同一目录
- [x] 5.5 实现 VideoCard 组件，展示视频封面、标题、UP主、时长和播放数
- [x] 5.6 使用 AsyncImage 加载封面图
- [x] 5.7 添加加载占位符和错误处理

## 6. FavoriteView 重构

- [x] 6.1 在 FavoriteView.swift 中添加 @State private var viewModel = FavoriteViewModel()
- [x] 6.2 替换静态 ForEach 为动态 ForEach(viewModel.folders)，使用 FavoriteFolderCard 组件
- [x] 6.3 添加 .task { await viewModel.loadFolders() } 在视图出现时加载数据
- [x] 6.4 添加 .refreshable { await viewModel.refresh() } 支持下拉刷新
- [x] 6.5 添加加载状态视图：if viewModel.isLoading { ProgressView() }
- [x] 6.6 添加错误状态视图：if let error = viewModel.errorMessage { ErrorView(message: error) }
- [x] 6.7 添加空状态视图：if viewModel.folders.isEmpty && !viewModel.isLoading { EmptyStateView() }
- [x] 6.8 添加未登录状态视图，根据 AccountManagerIOS.shared.isLoggedIn 判断
- [x] 6.9 使用 NavigationLink 跳转到 FavoriteFolderView

## 7. FavoriteFolderView 实现

- [x] 7.1 创建 FavoriteFolderView.swift 文件在 BilibiliLive-iOS/Views/ 目录
- [x] 7.2 定义 FavoriteFolderView 结构体，接受 folder: FavListDataIOS 参数
- [x] 7.3 添加 @State private var viewModel: FavoriteFolderViewModel
- [x] 7.4 在 init 中初始化 viewModel = FavoriteFolderViewModel(folder: folder)
- [x] 7.5 使用 ScrollView + LazyVStack 展示视频列表
- [x] 7.6 使用 VideoCard 组件渲染每个视频
- [x] 7.7 添加 .task { await viewModel.loadVideos() } 加载首页数据
- [x] 7.8 添加 .refreshable { await viewModel.refresh() } 支持下拉刷新
- [x] 7.9 实现滚动到底部检测，调用 viewModel.loadMore()
- [x] 7.10 添加底部加载指示器：if viewModel.isLoadingMore { ProgressView() }
- [x] 7.11 添加"已加载全部"提示：if !viewModel.hasMore { Text("已加载全部") }
- [x] 7.12 添加加载和错误状态处理

## 8. 自适应布局

- [x] 8.1 在 FavoriteFolderView 中使用 @Environment(\.horizontalSizeClass) 检测设备类型
- [x] 8.2 对于 iPhone 竖屏（compact），使用单列 LazyVStack 布局
- [x] 8.3 对于 iPad 或横屏（regular），使用 LazyVGrid 多列布局（2-3列）
- [x] 8.4 调整 VideoCard 尺寸以适应不同布局

## 9. 视频跳转预留

- [x] 9.1 在 FavoriteFolderView 中为 VideoCard 添加 .onTapGesture 或 Button 包装
- [x] 9.2 在 FavoriteFolderViewModel 中添加 navigateToVideo(_:) 方法（目前仅打印日志）
- [x] 9.3 检查 video.ogv 是否存在，区分普通视频和 OGV 内容
- [x] 9.4 添加 TODO 注释，说明待视频详情页实现后连接

## 10. 测试和优化

- [x] 10.1 使用 Xcode mcp 编译项目，修复编译错误
- [x] 10.2 在模拟器中测试加载收藏夹列表功能
- [x] 10.3 测试点击收藏夹进入内容页
- [x] 10.4 测试分页加载功能（滚动到底部）
- [x] 10.5 测试下拉刷新功能
- [x] 10.6 测试各种错误场景（网络错误、未登录等）
- [x] 10.7 测试空状态展示
- [x] 10.8 在真机上测试性能和用户体验
- [x] 10.9 测试 iPhone 和 iPad 的自适应布局
- [x] 10.10 优化图片加载性能和内存占用
