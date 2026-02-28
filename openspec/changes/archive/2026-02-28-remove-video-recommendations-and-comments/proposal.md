## 为什么

视频详情页当前包含推荐视频和热门评论两个sections，这些内容分散了用户对主要视频内容的注意力。简化界面可以让用户更专注于当前视频的核心信息（标题、UP主、播放信息、视频描述等），提升观看体验的沉浸感。

## 变更内容

- **移除推荐视频section**：删除相关视频推荐的 UI 组件、数据请求和展示逻辑
- **移除热门评论section**：删除评论展示的 UI 组件、数据请求和展示逻辑
- 保留其他核心功能：播放按钮、点赞/投币/收藏、UP主信息、分P列表、合集等

## 功能 (Capabilities)

### 新增功能
<!-- 无新增功能 -->

### 修改功能
- `video-detail-page`: 简化视频详情页布局，移除推荐视频和评论展示功能

## 影响

**受影响的代码**：
- `VideoDetailViewController.swift` - 主要视频详情页控制器
  - 移除 `recommandCollectionView` 相关代码
  - 移除 `replysCollectionView` 相关代码
  - 删除相关的网络请求（`WebRequest.requestReplys`）
  - 清理相关的数据模型属性和方法

**受影响的UI组件**：
- 推荐视频 collection view 及其布局
- 评论 collection view 及其布局
- 相关的 cell 类型（`RelatedVideoCell`, `ReplyCell`）

**用户体验变化**：
- 视频详情页将更加简洁，聚焦于当前视频信息
- 用户无法直接在详情页查看推荐视频和评论
- 需要通过其他方式（如返回首页）发现更多内容
