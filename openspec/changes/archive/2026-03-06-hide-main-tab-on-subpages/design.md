## 上下文

当前 iOS 版主导航由 `BilibiliLive-iOS/MainTabView.swift` 中的 `TabView` 承载，三个一级入口分别是“关注 / 收藏 / 我的”。每个 Tab 内部再各自使用 `NavigationStack` 或 `NavigationSplitView` 管理子页面，例如：

- `BilibiliLive-iOS/Views/FollowView.swift` 从动态卡片 push 到 `VideoDetailView`
- `BilibiliLive-iOS/Views/FavoriteView.swift` 先进入收藏夹，再由 `BilibiliLive-iOS/Views/FavoriteFolderView.swift` push 到视频详情
- `BilibiliLive-iOS/Views/ProfileView.swift` 在 iPhone 上通过 `NavigationStack` 进入历史记录、稍后再看、每周必看等子页面

当前这些二级页面没有统一声明隐藏主 Tab Bar，因此进入详情后底部主导航仍保持可见。该问题横跨多个一级 Tab 和多个子页面，需要一个统一且低侵入的处理方式。

约束：
- 只针对 iOS SwiftUI 工程处理，不复用 tvOS 代码
- 一级页面的 Tab 切换行为不能受影响
- push 式二级页面需要统一隐藏主 Tab，但不改变现有导航数据流
- iPad 的 `NavigationSplitView` 不应被强行改造成新的导航结构

## 目标 / 非目标

**目标：**
- 让主 Tab Bar 仅在一级页面显示
- 让通过 `NavigationStack` 进入的非根页面默认隐藏主 Tab Bar
- 明确覆盖视频详情页，并同步覆盖收藏夹详情、历史记录、稍后再看、每周必看等典型二级页面
- 保持返回上一级后的 Tab Bar 自动恢复

**非目标：**
- 不重构现有 `TabView` / `NavigationStack` 架构
- 不修改视频详情页的业务数据加载逻辑
- 不处理 sheet、fullScreenCover 等非 push 导航场景
- 不改变 iPad `NavigationSplitView` 的双栏交互模型

## 决策

### 决策 1：使用 SwiftUI 原生 `.toolbar(.hidden, for: .tabBar)` 控制二级页面 Tab 可见性

**选择**：在所有作为 push 目标的二级页面根视图上声明 `.toolbar(.hidden, for: .tabBar)`，而不是在 `MainTabView` 额外维护一套全局导航层级状态。

**理由：**
- SwiftUI 已提供对 tab bar 的原生隐藏能力，语义直接，维护成本低
- 由目标页面自行声明，最贴近页面职责，也更容易逐步扩展到新二级页
- 避免在 `TabView` 外层引入环境状态或路径监听，减少跨模块耦合

**替代方案考虑过但放弃：**
- ❌ 在 `MainTabView` 中集中监听所有导航路径：需要跨多个 Tab 汇总路径状态，复杂且脆弱
- ❌ 自定义 UIKit 容器接管 `UITabBarController` 显隐：实现成本高，且与现有纯 SwiftUI 结构不匹配

### 决策 2：按“可被 push 到的页面”而不是“入口页面”施加规则

**选择**：优先给 `VideoDetailView`、`FavoriteFolderView`、`WatchHistoryView`、`WatchLaterView`、`WeeklyWatchView`、`FollowUpsView`、`FollowBangumiView` 等二级页面加隐藏声明，而不是在入口页的每一个 `NavigationLink` 上做特殊处理。

**理由：**
- 同一个目标页面可能从多个入口进入，放在目标页更不容易遗漏
- 页面未来新增入口时无需重复修改入口逻辑
- 返回根页面时，SwiftUI 会自然恢复 Tab Bar，可减少额外状态回写

**替代方案考虑过但放弃：**
- ❌ 在每个 `navigationDestination` 闭包里包一层中间容器：重复代码多，容易不一致
- ❌ 只处理视频详情页：无法满足“进入二级菜单时隐藏主 Tab”的整体需求

### 决策 3：将 iPad Split View 视为一级结构，不强制隐藏主 Tab

**选择**：对 iPad `NavigationSplitView` 保持现状，仅在其内部继续 push 到更深页面时由目标页决定是否隐藏 Tab Bar。

**理由：**
- Split View 的主从布局本身就是一级信息架构的一部分，不等同于 iPhone 上的整页 push
- 强制在 detail 面板展示时隐藏 Tab，可能让 iPad 上的顶层切换成本上升
- 该策略既满足 iPhone 的主要诉求，也避免扩大改动面

**替代方案考虑过但放弃：**
- ❌ 只要进入任意 detail 就隐藏 Tab：会让 iPad 分栏使用体验变差，且不符合平台习惯

## 风险 / 权衡

- [部分二级页面遗漏隐藏声明] → 通过梳理所有 `NavigationLink` / `navigationDestination` 使用点，逐个覆盖主要二级页面，并在测试中验证
- [iPad 与 iPhone 行为感知不完全一致] → 在规范中明确以 push 式二级页面为准，避免对 split view 做过度约束
- [未来新增二级页面再次漏配] → 可补充一个轻量复用模式，例如统一的二级页 modifier 或代码评审检查项

## 迁移计划

1. 识别当前所有主 Tab 内的 push 目标页面
2. 给确认属于二级页面的目标视图添加 `.toolbar(.hidden, for: .tabBar)`
3. 优先验证视频详情、收藏夹详情、个人中心子页面的进入与返回行为
4. 在 iPhone 和 iPad 上各完成一次导航冒烟测试，确认一级导航仍可用

**回滚策略：**
- 本次变更集中在视图声明层，若出现问题，可逐个移除对应页面的 tab bar hidden 声明快速回滚
- 不涉及数据迁移、网络接口或持久化变更

## 开放问题

- 历史记录当前仍是占位详情页，是否在其真实视频详情接入时继续沿用同一隐藏规则？建议是。
- 是否需要抽出一个公共视图修饰器（如 `secondaryPageTabBarHidden()`）统一表达？若本次涉及页面较多，建议实现时一并抽取。