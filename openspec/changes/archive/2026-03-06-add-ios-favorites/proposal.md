## 为什么

iOS 应用目前只有一个基本的 FavoriteView 静态 UI 占位符，缺乏实际的收藏功能实现。tvOS 平台已经拥有完整的收藏模块，包括收藏夹列表、收藏内容展示、分页加载等功能。为了给 iOS 用户提供与 tvOS 一致的功能体验，需要将收藏模块迁移到 iOS 平台，使用 SwiftUI 和 @Observable 框架重新实现。

## 变更内容

- **新增**：iOS 收藏模块完整实现
  - 收藏夹列表展示（用户创建的收藏夹 + 用户收藏的订阅）
  - 收藏夹内容展示（视频列表）
  - 分页加载支持
  - 收藏视频详情跳转
  - 错误状态处理
  - 加载状态指示
- **新增**：数据模型层（iOS 版本）
  - FavListData 数据模型
  - FavData 数据模型
  - 与 API 的桥接请求
- **新增**：ViewModel 层
  - FavoriteViewModel：管理收藏夹列表
  - FavoriteFolderViewModel：管理单个收藏夹内容
- **修改**：现有 FavoriteView 从静态占位符改为动态数据驱动的完整功能页面

## 功能 (Capabilities)

### 新增功能
- `favorite-list`: 收藏夹列表展示功能，包括用户自建收藏夹和收藏的订阅收藏夹
- `favorite-content`: 收藏夹内容展示功能，包括视频列表、分页加载和跳转详情
- `favorite-data-models`: iOS 平台的收藏相关数据模型和 API 请求桥接
- `favorite-viewmodels`: 收藏模块的 ViewModel 层，使用 @Observable 实现状态管理

### 修改功能
无

## 影响

**受影响的文件**：
- `BilibiliLive-iOS/Views/FavoriteView.swift`：从静态 UI 改为完整功能实现
- `BilibiliLive-iOS/Models/`：新增收藏相关数据模型
- `BilibiliLive-iOS/ViewModels/`：新增 FavoriteViewModel 和 FavoriteFolderViewModel
- `BilibiliLive-iOS/Models/WebRequestBridge.swift`：可能需要新增收藏相关 API 请求方法

**API 依赖**：
- 依赖 tvOS 项目中已有的 B站收藏 API 接口
- 需要桥接的 API：
  - 收藏夹列表获取
  - 收藏夹内容获取
  - 收藏订阅列表获取

**技术栈**：
- SwiftUI
- @Observable 框架
- Async/await
- 参考 tvOS 的 API 实现但不共享代码
