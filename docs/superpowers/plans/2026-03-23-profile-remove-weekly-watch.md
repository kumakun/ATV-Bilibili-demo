# Profile Remove Weekly Watch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 从 iOS 我的页删除“每周必看”功能，并清理只服务该功能的代码路径。

**Architecture:** 先为 Profile 主功能入口建立可测试的统一路由配置，再删除 `weeklyWatch` 相关 UI、状态、模型与接口桥接。这样可以同时完成行为删除和重复代码收敛。

**Tech Stack:** Swift, SwiftUI, Observation, Testing, Xcode MCP

---

### Task 1: 为删除行为建立测试约束

**Files:**
- Create: `BilibiliLive-iOSTests/ProfileRouteTests.swift`
- Modify: `BilibiliLive-iOS/Models/ProfileModels.swift`

- [ ] **Step 1: Write the failing test**

```swift
import Testing
@testable import BilibiliLive_iOS

struct ProfileRouteTests {
  @Test
  func primaryRoutesDoNotContainWeeklyWatch() {
    #expect(ProfileRoute.primaryRoutes.contains(.weeklyWatch) == false)
  }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: Xcode MCP `RunSomeTests`
Expected: FAIL because `ProfileRoute.primaryRoutes` does not exist yet

- [ ] **Step 3: Write minimal implementation**

```swift
extension ProfileRoute {
  static let primaryRoutes: [ProfileRoute] = [
    .followUps,
    .followBangumi,
    .watchHistory,
    .watchLater,
  ]
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: Xcode MCP `RunSomeTests`
Expected: PASS

### Task 2: 删除每周必看入口并收敛菜单配置

**Files:**
- Modify: `BilibiliLive-iOS/Views/ProfileView.swift`
- Modify: `BilibiliLive-iOS/Models/ProfileModels.swift`

- [ ] **Step 1: 让 iPad 与 iPhone 共享 `ProfileRoute.primaryRoutes` 与菜单元数据**
- [ ] **Step 2: 删除 `weeklyWatch` 路由与对应菜单项**
- [ ] **Step 3: 运行相关测试确认路由配置仍通过**

### Task 3: 删除每周必看专用实现

**Files:**
- Delete: `BilibiliLive-iOS/Views/Profile/WeeklyWatchView.swift`
- Delete: `BilibiliLive-iOS/ViewModels/WeeklyWatchViewModel.swift`
- Modify: `BilibiliLive-iOS/Models/ProfileModels.swift`
- Modify: `BilibiliLive-iOS/Models/ApiRequestBridge.swift`
- Modify: `BilibiliLive-iOS/Models/WebRequestBridge.swift`

- [ ] **Step 1: 删除每周必看页面与 ViewModel**
- [ ] **Step 2: 删除 `WeeklyList`、`WeeklyVideo` 和专用请求桥接**
- [ ] **Step 3: 构建工程，确认无残留引用**

### Task 4: 完整验证

**Files:**
- Test: `BilibiliLive-iOSTests/ProfileRouteTests.swift`

- [ ] **Step 1: 运行相关单元测试**
- [ ] **Step 2: 构建 `BilibiliLive-iOS`**
- [ ] **Step 3: 检查工作区 diff，确认只包含本次删除与清理**
