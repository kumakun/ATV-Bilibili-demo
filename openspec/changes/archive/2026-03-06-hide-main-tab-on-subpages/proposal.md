## 为什么

当前 iOS 版在主 Tab 内继续进入二级页面时，底部仍持续显示“关注 / 收藏 / 我的”主导航，容易让页面层级感变弱，也会分散用户在详情页或子功能页上的注意力。随着视频详情、收藏夹详情、个人中心子页面逐步完善，需要统一二级页面的导航表现，使主 Tab 仅承担一级导航职责。

## 变更内容

- 调整 iOS 主导航行为：主 Tab Bar 仅在一级页面显示
- 当用户从“关注 / 收藏 / 我的”进入二级页面时，隐藏主 Tab Bar
- 当用户从二级页面返回一级页面时，恢复显示主 Tab Bar
- 将视频详情页作为首个明确覆盖场景，并要求同类 push 进入的子页面遵循一致规则

## 功能 (Capabilities)

### 新增功能

无新增功能。

### 修改功能

- `main-navigation`: 主 Tab Bar 的可见范围从“始终显示”调整为“仅一级页面显示，二级页面隐藏”
- `ios-video-navigation`: 进入视频详情页时需要隐藏主 Tab Bar，返回上一级后恢复显示

## 影响

### 代码影响
- `BilibiliLive-iOS/MainTabView.swift`：主 Tab 容器可能需要统一处理二级页面的 Tab Bar 可见性
- `BilibiliLive-iOS/Views/FollowView.swift`：从关注页进入视频详情时需要隐藏主 Tab
- `BilibiliLive-iOS/Views/FavoriteView.swift` 与 `BilibiliLive-iOS/Views/FavoriteFolderView.swift`：收藏相关二级导航需要遵循同样规则
- `BilibiliLive-iOS/Views/ProfileView.swift` 及其子页面：个人中心的二级页面导航需要统一隐藏主 Tab
- `BilibiliLive-iOS/Views/VideoDetail/VideoDetailView.swift`：视频详情页需要明确声明隐藏 Tab Bar

### 用户影响
- 用户进入二级页面时界面更聚焦，减少一级导航干扰
- 返回一级页面后仍可继续使用“关注 / 收藏 / 我的”主导航

### 依赖影响
- 无后端 API 变更
- 无新增第三方依赖
