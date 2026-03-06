## 为什么

当前 iOS 主 Tab 中的“关注”命名更偏向关系语义，无法准确传达该页面以最新动态更新为核心的使用目的；同时，`FollowView` 仍以单列列表展示内容，在 iPhone 和更大屏幕设备上都没有充分利用横向空间，导致浏览效率偏低。

现在调整该入口命名与布局体验，可以让用户更直观地理解页面职责，并为后续持续优化动态流信息密度打下基础。

## 变更内容

- 将 iOS 主 Tab 中 `FollowView` 对应的标签文案由“关注”改为“更新”。
- 调整 `FollowView` 的内容展示体验，将当前单列流改为网格化多列布局。
- 在 iPhone 上固定使用 2 列布局；在更宽设备或更大可用宽度环境下，使用可自适应增加列数的多列布局。
- 保持现有动态加载、分页、刷新、空状态与跳转视频详情等行为不变，仅优化信息架构与呈现方式。

## 功能 (Capabilities)

### 新增功能
<!-- 无 -->

### 修改功能
- `main-navigation`: 将主 Tab 第一项的显示名称从“关注”调整为“更新”，并保持该标签仍作为动态内容入口。
- `follow-feed`: 将关注动态页面的内容展示从单列列表升级为多列网格，其中 iPhone 必须为 2 列，更宽环境下必须支持自适应多列。

## 影响

- iOS SwiftUI 主导航：`BilibiliLive-iOS/MainTabView.swift`
- iOS SwiftUI 关注动态页：`BilibiliLive-iOS/Views/FollowView.swift`
- iOS 动态页视图模型与分页触发逻辑：`BilibiliLive-iOS/ViewModels/FollowViewModel.swift`
- OpenSpec 规格：`openspec/specs/main-navigation/spec.md`、`openspec/specs/follow-feed/spec.md`
