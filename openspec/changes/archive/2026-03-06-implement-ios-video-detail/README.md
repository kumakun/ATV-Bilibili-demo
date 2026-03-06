# iOS视频详情页实现

## 概述

本次变更实现了完整的iOS视频详情页功能，参考tvOS平台的VideoDetailViewController，使用SwiftUI和@Observable架构重新实现。

## 主要功能

### 1. 视频播放
- 使用AVKit的VideoPlayer组件
- 16:9宽高比约束，适配所有iOS设备
- 支持播放/暂停、进度控制
- 播放进度自动保存和恢复

### 2. 视频信息展示
- 视频标题、BVID、时长、发布日期
- UP主信息（头像、昵称、关注状态）
- 统计数据（播放量、弹幕数、点赞数、投币数、收藏数）
- 可展开/收起的视频简介

### 3. 互动操作
- 点赞/取消点赞
- 投币（支持1-2个硬币）
- 收藏到收藏夹
- 关注UP主
- 分享视频

### 4. 分P支持
- 多分P视频列表展示
- 当前播放分P高亮
- 点击切换分P播放

### 5. 导航集成
- 从关注动态页面跳转
- 从收藏夹页面跳转
- 支持导航栏返回

## 技术架构

### 数据层
- **VideoDetailModels.swift**: 视频详情数据模型
- **WebRequestBridge.swift**: 视频详情和播放地址API
- **ApiRequestBridge.swift**: 互动操作API（点赞、投币、收藏、关注）

### ViewModel层
- **VideoDetailViewModel.swift**: 统一状态管理
  - @Observable宏实现响应式更新
  - 异步数据加载和错误处理
  - 用户交互操作逻辑
  - 播放进度管理

### UI层
所有组件位于`BilibiliLive-iOS/Views/VideoDetail/`目录：

1. **VideoPlayerView.swift**: 视频播放器组件
2. **VideoInfoSection.swift**: 视频基本信息
3. **UploaderInfoView.swift**: UP主信息和关注按钮
4. **VideoStatsView.swift**: 统计数据展示
5. **VideoDescriptionSection.swift**: 可展开的视频简介
6. **VideoActionBar.swift**: 互动操作栏
7. **VideoEpisodesSection.swift**: 分P列表
8. **VideoDetailView.swift**: 主容器视图

## 用户认证

所有互动操作（点赞、投币、收藏、关注）都会先检查用户登录状态：
- 未登录时显示提示信息
- 已登录时执行对应操作
- 使用AccountManagerIOS统一管理登录状态

## 响应式布局

- iPhone竖屏：单列布局，ScrollView垂直滚动
- iPhone横屏：自适应布局
- iPad：利用更大屏幕空间，优化间距和尺寸

## 导航路径

```
FollowView → VideoDetailView
             ↑ aid参数
FavoriteFolderView → VideoDetailView
                     ↑ aid参数
```

## 文件清单

### 新增文件（12个）
1. `/BilibiliLive-iOS/Models/VideoDetailModels.swift`
2. `/BilibiliLive-iOS/ViewModels/VideoDetailViewModel.swift`
3. `/BilibiliLive-iOS/Views/VideoDetail/VideoPlayerView.swift`
4. `/BilibiliLive-iOS/Views/VideoDetail/VideoInfoSection.swift`
5. `/BilibiliLive-iOS/Views/VideoDetail/UploaderInfoView.swift`
6. `/BilibiliLive-iOS/Views/VideoDetail/VideoStatsView.swift`
7. `/BilibiliLive-iOS/Views/VideoDetail/VideoDescriptionSection.swift`
8. `/BilibiliLive-iOS/Views/VideoDetail/VideoActionBar.swift`
9. `/BilibiliLive-iOS/Views/VideoDetail/VideoEpisodesSection.swift`
10. `/BilibiliLive-iOS/Views/VideoDetail/VideoDetailView.swift`

### 修改文件（4个）
1. `/BilibiliLive-iOS/Models/WebRequestBridge.swift` - 添加requestVideoDetail、requestPlayUrl方法
2. `/BilibiliLive-iOS/Models/ApiRequestBridge.swift` - 添加like、coin、favorite、follow API
3. `/BilibiliLive-iOS/Views/FollowView.swift` - 添加VideoDetailView导航
4. `/BilibiliLive-iOS/Views/FavoriteFolderView.swift` - 添加VideoDetailView导航

## 待优化项

1. **收藏功能**：当前为简化实现，完整版需要收藏夹选择器
2. **OGV内容**：番剧、影视等内容需要单独的详情页
3. **弹幕功能**：需要集成弹幕播放器
4. **推荐视频**：可在详情页底部添加相关推荐
5. **下载功能**：支持离线下载

## 测试状态

- ✅ 代码编译通过，无错误
- ✅ 所有UI组件已实现
- ✅ 导航集成完成
- ✅ 用户认证检查已添加
- ⏳ 真机功能测试待进行

## 参考文档

- tvOS参考：`BilibiliLive/Component/Video/VideoDetailViewController.swift`
- API文档：[B站API文档](https://github.com/SocialSisterYi/bilibili-API-collect)
