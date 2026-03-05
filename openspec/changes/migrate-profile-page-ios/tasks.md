## 1. 准备工作和数据模型

- [x] 1.1 创建 Profile 目录结构（Views/Profile/ 和 ViewModels/）
- [x] 1.2 创建 ProfileModels.swift 定义数据模型（UserProfile、FollowingUser、HistoryItem 等）
- [x] 1.3 扩展 ApiRequestBridge 添加获取用户资料的方法
- [x] 1.4 扩展 WebRequestBridge 实现对应的网络请求

## 2. 重构 ProfileView 主页面

- [x] 2.1 创建 ProfileViewModel 并集成 AccountManagerIOS
- [x] 2.2 实现 ProfileViewModel.loadProfile() 方法加载用户数据
- [x] 2.3 重构 UserInfoCard 显示真实头像、用户名和签名
- [x] 2.4 实现 UserStatsView 显示真实的关注数、粉丝数、获赞数
- [x] 2.5 监听 AccountManagerIOS 的账号更新通知自动刷新
- [x] 2.6 实现页面加载时自动刷新用户资料
- [x] 2.7 实现二维码功能入口（如需要）

## 3. 实现导航系统

- [x] 3.1 定义 ProfileRoute 枚举（followUps、followBangumi、watchHistory 等）
- [x] 3.2 在 ProfileView 中添加 NavigationStack 和路由处理
- [x] 3.3 重构 FunctionListSection 将静态按钮改为可导航按钮
- [x] 3.4 实现功能列表项点击导航逻辑

## 4. 实现关注 UP 主列表

- [x] 4.1 扩展 ApiRequestBridge 添加 requestFollowingUps(page:) 方法
- [x] 4.2 创建 FollowingUser 数据模型
- [x] 4.3 创建 FollowUpsViewModel 实现分页加载逻辑
- [x] 4.4 创建 FollowUpsView 展示 UP 主列表（头像、用户名、签名）
- [x] 4.5 实现网格布局适配 iOS 设备
- [x] 4.6 实现滚动到底部自动加载更多
- [x] 4.7 实现防止重复请求机制
- [x] 4.8 实现点击 UP 主卡片导航到个人空间（如需要）
- [x] 4.9 添加加载状态和错误处理

## 5. 实现历史记录

- [x] 5.1 扩展 ApiRequestBridge 添加 requestHistory() 方法
- [x] 5.2 创建 HistoryItem 数据模型
- [x] 5.3 创建 WatchHistoryViewModel 实现历史记录加载
- [x] 5.4 创建 WatchHistoryView 展示历史记录列表
- [x] 5.5 实现显示视频封面、标题、UP 主信息
- [x] 5.6 实现显示观看进度和时间
- [x] 5.7 实现点击历史记录导航到视频详情页
- [x] 5.8 实现页面显示时自动刷新逻辑
- [x] 5.9 添加空状态和错误处理

## 6. 实现稍后再看

- [x] 6.1 扩展 ApiRequestBridge 添加 requestToView() 方法
- [x] 6.2 创建 ToViewItem 数据模型
- [x] 6.3 创建 WatchLaterViewModel 实现稍后再看加载
- [x] 6.4 创建 WatchLaterView 展示稍后再看列表
- [x] 6.5 实现显示视频详细信息（封面、标题、时长、统计）
- [x] 6.6 实现时长格式化（分:秒 或 时:分:秒）
- [x] 6.7 实现长按删除功能（显示确认对话框）
- [x] 6.8 扩展 ApiRequestBridge 添加删除稍后再看的方法
- [x] 6.9 实现删除后自动刷新列表
- [x] 6.10 实现点击视频导航到详情页

## 7. 实现追番追剧

- [x] 7.1 扩展 ApiRequestBridge 添加 requestFollowBangumi(type:page:) 方法
- [x] 7.2 创建 BangumiItem 数据模型
- [x] 7.3 创建 FollowBangumiViewModel 实现番剧和影视数据加载
- [x] 7.4 创建 FollowBangumiView 实现分类标签切换（番剧/影视）
- [x] 7.5 实现番剧列表展示（封面、标题、进度）
- [x] 7.6 实现显示最新集信息和更新标记
- [x] 7.7 实现分页加载逻辑
- [x] 7.8 实现点击番剧导航到详情页
- [x] 7.9 添加加载状态和错误处理

## 8. 实现每周必看

- [x] 8.1 扩展 ApiRequestBridge 添加 requestWeeklyWatchList() 方法
- [x] 8.2 扩展 ApiRequestBridge 添加 requestWeeklyWatch(wid:) 方法
- [x] 8.3 创建 WeeklyList 和 WeeklyVideo 数据模型
- [x] 8.4 创建 WeeklyWatchViewModel 实现每周必看加载
- [x] 8.5 创建 WeeklyWatchView 展示推荐视频列表
- [x] 8.6 实现显示期号标题头部
- [x] 8.7 实现自动加载最新一期
- [x] 8.8 实现点击视频导航到详情页
- [x] 8.9 添加加载状态和错误处理

## 9. 实现账号切换

- [x] 9.1 创建 AccountSwitcherViewModel 获取账号列表
- [x] 9.2 创建 AccountSwitcherView 展示账号列表
- [x] 9.3 实现显示账号头像和用户名
- [x] 9.4 实现标记当前激活账号
- [x] 9.5 实现点击账号切换逻辑
- [x] 9.6 实现"添加新账号"按钮和导航
- [x] 9.7 实现关闭按钮和手势关闭
- [x] 9.8 实现监听账号更新自动刷新列表
- [x] 9.9 适配 iOS 设备的网格或列表布局

## 10. 实现登出功能

- [x] 10.1 在 FunctionListView 中添加登出按钮
- [x] 10.2 实现点击登出显示确认对话框
- [x] 10.3 扩展 ApiRequestBridge 添加 logout() 方法
- [x] 10.4 实现确认登出后调用 WebRequest.logout 和 ApiRequest.logout
- [x] 10.5 实现多账号处理逻辑（切换到其他账号或显示登录页）
- [x] 10.6 实现登出后清除用户数据和更新界面
- [x] 10.7 添加登出失败的错误处理

## 11. 通用组件和优化

- [x] 11.1 创建通用的 LoadingView 组件
- [x] 11.2 创建通用的 ErrorView 组件（支持重试）
- [x] 11.3 创建通用的 EmptyStateView 组件
- [x] 11.4 实现图片加载组件（AsyncImage 或 CachedAsyncImage）
- [x] 11.5 优化列表性能（使用 LazyVStack/LazyVGrid）
- [x] 11.6 适配不同屏幕尺寸（iPhone/iPad）
- [x] 11.7 添加下拉刷新支持（关注列表、历史记录）

## 12. 测试和调试

- [x] 12.1 测试 ProfileView 主页面的数据加载和显示
- [x] 12.2 测试所有列表页面的分页加载
- [x] 12.3 测试账号切换后数据刷新
- [x] 12.4 测试登出流程（单账号和多账号场景）
- [x] 12.5 测试导航流程（进入和返回）
- [x] 12.6 测试错误处理和重试功能
- [x] 12.7 测试不同设备尺寸的布局适配
- [x] 12.8 测试删除稍后再看视频功能
- [x] 12.9 修复发现的 bug 和优化用户体验
