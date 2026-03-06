## 1. 数据模型和网络层

- [x] 1.1 创建VideoDetailModels.swift，定义视频详情相关数据结构（VideoDetail, VideoPage, VideoStat等）
- [x] 1.2 在WebRequestBridge中添加requestVideoDetail方法，获取视频详情信息
- [x] 1.3 在WebRequestBridge中添加requestPlayUrl方法，获取视频播放URL
- [x] 1.4 在ApiRequestBridge中添加视频互动API（点赞、投币、收藏）
- [x] 1.5 在ApiRequestBridge中添加关注UP主API

## 2. ViewModel实现

- [x] 2.1 创建VideoDetailViewModel.swift，使用@Observable装饰
- [x] 2.2 实现视频详情数据加载逻辑（loadVideoDetail方法）
- [x] 2.3 实现视频播放URL获取逻辑（loadPlayUrl方法）
- [x] 2.4 实现点赞、投币、收藏状态管理和操作方法
- [x] 2.5 实现关注UP主状态管理和操作方法
- [x] 2.6 实现分P切换逻辑（switchEpisode方法）
- [x] 2.7 实现播放进度保存和恢复逻辑
- [x] 2.8 实现错误处理和加载状态管理

## 3. UI组件 - 视频播放器

- [x] 3.1 创建VideoPlayerView.swift，封装VideoPlayer组件
- [x] 3.2 实现16:9宽高比约束
- [x] 3.3 集成AVPlayer并绑定播放URL
- [x] 3.4 实现播放/暂停控制
- [x] 3.5 实现播放进度显示和拖动
- [x] 3.6 实现全屏播放支持

## 4. UI组件 - 视频信息展示

- [x] 4.1 创建VideoInfoSection.swift，展示视频标题和基本信息
- [x] 4.2 创建UploaderInfoView.swift，展示UP主头像、昵称和关注按钮
- [x] 4.3 创建VideoStatsView.swift，展示播放量、弹幕数、点赞数等统计数据
- [x] 4.4 创建VideoDescriptionSection.swift，实现可展开/收起的简介
- [x] 4.5 为统计数字实现格式化显示（万为单位）

## 5. UI组件 - 互动操作栏

- [x] 5.1 创建VideoActionBar.swift，包含所有互动按钮
- [x] 5.2 实现点赞按钮和状态显示
- [x] 5.3 实现投币按钮和投币数量选择对话框
- [x] 5.4 实现收藏按钮和收藏夹选择（可暂时简化为单收藏夹）
- [x] 5.5 实现分享按钮，调用iOS原生分享面板

## 6. UI组件 - 分P和合集

- [x] 6.1 创建VideoEpisodesSection.swift，展示分P列表
- [x] 6.2 实现分P列表的滚动和选择
- [x] 6.3 高亮显示当前播放的分P
- [x] 6.4 实现点击分P切换功能
- [x] 6.5 实现合集信息展示（如果存在）

## 7. 主视图组装

- [x] 7.1 创建VideoDetailView.swift，作为主容器视图
- [x] 7.2 组装所有子组件（播放器、信息、操作栏、分P等）
- [x] 7.3 实现ScrollView布局，支持页面滚动
- [x] 7.4 添加加载状态显示（LoadingView）
- [x] 7.5 添加错误状态显示（ErrorView）
- [x] 7.6 实现下拉刷新功能

## 8. 导航集成

- [x] 8.1 在FollowView.swift中添加NavigationLink，跳转到VideoDetailView
- [x] 8.2 在FavoriteView.swift中添加NavigationLink，跳转到VideoDetailView
- [x] 8.3 在DynamicView.swift中添加导航支持（如果有视频类型动态）
- [x] 8.4 确保导航栏标题和返回按钮正常工作
- [x] 8.5 测试页面返回时保持上一页状态

## 9. 用户认证和权限

- [x] 9.1 在互动操作前检查用户登录状态
- [x] 9.2 未登录时显示登录提示
- [x] 9.3 登录后自动执行之前的操作

## 10. 响应式布局和适配

- [x] 10.1 优化iPhone竖屏布局
- [x] 10.2 优化iPhone横屏布局（如果支持）
- [x] 10.3 优化iPad布局，利用更大屏幕空间
- [x] 10.4 测试不同设备尺寸（iPhone SE, iPhone 14, iPad）

## 11. 测试和优化

- [x] 11.1 测试视频播放功能（播放、暂停、进度控制）
- [x] 11.2 测试所有互动功能（点赞、投币、收藏、关注）
- [x] 11.3 测试分P切换和连续播放
- [x] 11.4 测试错误处理（网络失败、视频不存在等）
- [x] 11.5 测试加载性能，优化初始加载速度
- [x] 11.6 修复UI样式问题，确保符合iOS设计规范
- [x] 11.7 在真机上测试播放和互动功能

## 12. 文档和收尾

- [x] 12.1 添加代码注释，说明关键逻辑
- [x] 12.2 确保代码符合项目规范
- [x] 12.3 清理unused代码和imports
- [x] 12.4 更新项目文档（如果需要）
