## 为什么

iOS 版本的"我的"页面（ProfileView）目前仅有基础的静态 UI 展示，缺少 tvOS 版本（PersonalViewController）中已实现的核心功能，包括用户信息动态加载、关注列表、历史记录、稍后再看、追番追剧等。为了保持功能一致性并提供完整的用户体验，需要将 tvOS 的"我的"模块功能迁移到 iOS 平台。

## 变更内容

- **新增**：用户信息动态加载（头像、用户名、个人签名、统计数据）
- **新增**：关注 UP 主列表页面
- **新增**：追番追剧功能
- **新增**：历史记录页面
- **新增**：稍后再看页面
- **新增**：每周必看功能
- **新增**：账号切换功能
- **新增**：登出功能
- **修改**：重构现有的 ProfileView，将静态占位符替换为真实的用户数据和可导航的功能列表
- **修改**：集成现有的 API 请求层（ApiRequestBridge、WebRequestBridge）以获取用户数据

## 功能 (Capabilities)

### 新增功能
- `user-profile-info`: 用户个人信息展示，包括头像、用户名、个人签名、统计数据（关注、粉丝、获赞）的动态加载
- `follow-ups-list`: 关注的 UP 主列表展示和管理
- `follow-bangumi`: 追番追剧列表，展示用户关注的番剧和电视剧
- `watch-history`: 观看历史记录列表，支持查看和继续观看
- `watch-later`: 稍后再看列表，展示用户添加的稍后观看视频
- `weekly-watch`: 每周必看推荐列表
- `account-switching`: 账号切换功能，支持多账号登录和切换
- `logout-flow`: 登出流程，清除当前登录状态

### 修改功能
无（现有的 ProfileView 是新建的静态页面，没有对应的规范需要修改）

## 影响

**受影响的文件**：
- `BilibiliLive-iOS/Views/ProfileView.swift` - 主要重构
- `BilibiliLive-iOS/Models/AccountManagerIOS.swift` - 可能需要扩展账号管理功能
- `BilibiliLive-iOS/Models/ApiRequestBridge.swift` - 可能需要添加新的 API 调用桥接
- 需要新建多个 View 和 ViewModel 文件

**依赖的现有代码**：
- tvOS 的 `BilibiliLive/Module/Personal/` 模块（作为功能参考，不共享代码）
- `BilibiliLive/Request/ApiRequest.swift` - API 请求逻辑（需要在 iOS 侧重新实现）
- `BilibiliLive/AccountManager.swift` - 账号管理逻辑（需要在 iOS 侧适配）

**技术栈**：
- SwiftUI 用于 UI 构建
- @Observable 框架用于状态管理
- NavigationStack 用于页面导航
- 需要参考 tvOS 的数据模型但使用 iOS 原生的方式重新实现

**用户体验影响**：
- 用户将能够在 iOS 端访问完整的个人中心功能
- 提供与 tvOS 版本一致的功能体验
- 改善当前 iOS 版本功能不完整的问题
