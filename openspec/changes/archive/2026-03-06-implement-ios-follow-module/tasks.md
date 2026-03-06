# 任务清单：实现 iOS 关注模块

## 1. 创建数据模型

- [x] 1.1 创建 FollowModels.swift 文件，定义 DynamicFeedInfo 和 DynamicFeedData 数据模型
- [x] 1.2 定义 DynamicFeedData 的子结构（Modules、ModuleAuthor、ModuleDynamic、Major、Archive、Pgc、Stat 等）
- [x] 1.3 实现 Codable 协议支持 JSON 解析
- [x] 1.4 添加计算属性：aid, cid, title, ownerName, pic, avatar, duration, playCountString, danmakuCountString 等
- [x] 1.5 实现 Identifiable 协议，使用 id_str 作为唯一标识

## 2. 扩展 API 请求桥接

- [x] 2.1 在 WebRequestBridge.swift 中添加 requestFollowsFeed 静态方法
- [x] 2.2 实现 API 请求逻辑：使用 "https://api.bilibili.com/x/polymer/web-dynamic/v1/feed/all" 端点
- [x] 2.3 添加请求参数：type（"all"）、timezone_offset（"-480"）、page、offset
- [x] 2.4 实现响应解析，返回 DynamicFeedInfo（包含 items、offset、has_more 等）
- [x] 2.5 实现错误处理，抛出 RequestError

## 3. 创建 FollowViewModel

- [x] 3.1 创建 FollowViewModel.swift 文件，使用 @Observable 和 @MainActor
- [x] 3.2 定义状态属性：feeds, isLoading, isLoadingMore, errorMessage, hasMore, lastOffset
- [x] 3.3 实现 loadInitial() 方法：初始加载第一页数据，重置 lastOffset 和 feeds
- [x] 3.4 实现 refresh() 方法：下拉刷新，清空现有数据重新加载
- [x] 3.5 实现 loadMore() 方法：加载下一页数据，使用 lastOffset
- [x] 3.6 实现 loadMoreIfNeeded(currentFeed:) 方法：判断是否需要触发加载更多
- [x] 3.7 实现防抖逻辑：使用 isLoading 和 isLoadingMore 标志防止重复请求
- [x] 3.8 实现过滤逻辑：只保留包含视频内容的动态（videoFeeds 计算属性）
- [x] 3.9 添加错误处理：捕获异常并设置 errorMessage

## 4. 重构 FollowView 界面

- [x] 4.1 移除当前的 mock 数据和 FollowVideoCard 静态实现
- [x] 4.2 添加 @State private var viewModel = FollowViewModel()
- [x] 4.3 实现筛选器 Picker（全部/视频/直播），使用 @State private var selectedFilter
- [x] 4.4 实现主内容区域：根据状态显示加载中、错误、空状态或列表
- [x] 4.5 使用 ScrollView + LazyVStack 展示动态列表
- [x] 4.6 实现 DynamicFeedCard 组件：展示视频封面、标题、UP 主信息、播放数据
- [x] 4.7 添加 .task { await viewModel.loadInitial() } 触发初始加载
- [x] 4.8 添加 .refreshable { await viewModel.refresh() } 支持下拉刷新
- [x] 4.9 在每个 DynamicFeedCard 上添加 .onAppear 触发 loadMoreIfNeeded

## 5. 实现视频卡片组件

- [x] 5.1 创建 DynamicFeedCard 结构体，接收 DynamicFeedData 参数
- [x] 5.2 实现视频封面显示（AsyncImage，带占位符）
- [x] 5.3 实现视频标题显示（限制行数，支持换行）
- [x] 5.4 实现 UP 主信息行：头像 + 名称 + 发布时间
- [x] 5.5 实现播放数据行：播放量 + 弹幕数 + 时长
- [x] 5.6 实现卡片样式：背景、圆角、阴影
- [x] 5.7 使用 NavigationLink 支持点击跳转（value: feed）

## 6. 实现视频详情导航

- [x] 6.1 在 FollowView 的 NavigationStack 中添加 .navigationDestination(for: DynamicFeedData.self)
- [x] 6.2 创建或复用视频详情页面占位视图（VideoDetailPlaceholderView）
- [x] 6.3 传递必要的视频参数（aid、cid、epid）到详情页
- [x] 6.4 测试点击卡片能否正确导航

## 7. 实现加载状态和错误处理

- [x] 7.1 实现首次加载的 ProgressView（居中显示，带"加载中..."文本）
- [x] 7.2 实现加载更多的 ProgressView（列表底部小型指示器）
- [x] 7.3 实现错误状态视图（显示错误信息 + 重试按钮）
- [x] 7.4 实现空状态视图（ContentUnavailableView："暂无关注动态"）
- [x] 7.5 确保所有状态切换流畅自然

## 8. UI 调整和优化

- [x] 8.1 调整卡片布局，适配 iPhone 和 iPad 屏幕尺寸
- [x] 8.2 优化封面图片加载性能（设置合适的缓存策略）
- [x] 8.3 调整字体大小、颜色、间距等视觉细节
- [x] 8.4 测试滚动性能，确保列表流畅
- [x] 8.5 测试深色模式下的显示效果
- [x] 8.6 测试横屏模式（iPad）的布局

## 9. 测试和验证

- [x] 9.1 测试初始加载功能：打开页面能否正确加载动态
- [x] 9.2 测试下拉刷新功能：能否正确刷新数据
- [x] 9.3 测试分页加载功能：滚动到底部能否自动加载更多
- [x] 9.4 测试防重复请求：快速滚动时不会发起多个请求
- [x] 9.5 测试错误处理：网络错误时能否显示错误信息和重试按钮
- [x] 9.6 测试空状态：没有关注动态时能否显示空状态提示
- [x] 9.7 测试视频详情导航：点击卡片能否跳转到详情页
- [x] 9.8 测试筛选器功能：切换筛选器能否正常工作（当前所有选项显示相同内容）
- [x] 9.9 在真机上测试完整流程
