# iOS 普通视频多档清晰度与自动 CDN 兜底 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 iOS 普通视频播放补齐高 / 中 / 低三档清晰度切换，并在同档位内支持主备 CDN 自动失败切换。

**Architecture:** 在 `BilibiliLive-iOS` 内新增一个轻量档位模型，先把当前视频的可用画质映射成高 / 中 / 低档，再扩展 `DASHStreamSelection` 和 `DASHResourceLoader`，分别负责按档位选流以及在同一流内轮转 `baseUrl + backupUrl`。`VideoDetailViewModel` 负责缓存 `playurl`、驱动档位切换与续播，SwiftUI 层只负责展示档位入口并回调 ViewModel。

**Tech Stack:** Swift, SwiftUI, Observation, AVFoundation, Alamofire, Xcode MCP Testing

---

## File Structure

- Create: `BilibiliLive-iOS/Models/VideoPlaybackQuality.swift`
  - iOS 专用档位枚举、档位展示文案、动态归类结果与质量组映射逻辑
- Modify: `BilibiliLive-iOS/Utilities/DASHStreamSelection.swift`
  - 将“总是选最高画质”扩展为“按指定档位选流”，并统一构建有序的主备 URL 列表
- Modify: `BilibiliLive-iOS/Utilities/DASHResourceLoader.swift`
  - 为视频流和音频流引入独立的 CDN 候选索引与失败切换逻辑
- Modify: `BilibiliLive-iOS/Utilities/DASHVideoPlayer.swift`
  - 把档位选择能力接进播放器工厂，允许基于目标档位建链
- Modify: `BilibiliLive-iOS/ViewModels/VideoDetailViewModel.swift`
  - 缓存 `VideoPlayURLInfo`、暴露档位列表、处理切档与续播
- Modify: `BilibiliLive-iOS/Views/VideoDetail/VideoPlayerView.swift`
  - 增加 iOS 风格的高 / 中 / 低档位切换 UI
- Modify: `BilibiliLive-iOS/Views/VideoDetail/VideoDetailView.swift`
  - 把 ViewModel 的档位状态和切换动作接进播放器区域
- Create or Modify: `BilibiliLive-iOSTests/VideoPlaybackQualityTests.swift`
  - 纯策略测试：档位归类、可用档位展示
- Modify: `BilibiliLive-iOSTests/DASHStreamSelectionTests.swift`
  - 档位选流、编码优先级、URL 排序与去重测试
- Modify: `BilibiliLive-iOSTests/VideoDetailPlaybackFlowTests.swift`
  - ViewModel 首次加载、切档续播、切分 P 重算档位测试
- Modify: `BilibiliLive-iOSTests/DASHResourceLoaderTests.swift`
  - CDN 失败轮转测试

### Task 1: 建立档位模型与归类规则

**Files:**
- Create: `BilibiliLive-iOS/Models/VideoPlaybackQuality.swift`
- Test: `BilibiliLive-iOSTests/VideoPlaybackQualityTests.swift`

- [ ] **Step 1: 写出档位归类失败测试**

在 `BilibiliLive-iOSTests/VideoPlaybackQualityTests.swift` 新建测试，覆盖：

- `120, 80, 64, 32` 会映射出高 / 中 / 低三档
- `120, 80` 只映射出高 / 低两档
- `64` 只映射出单档

测试应直接断言档位顺序和每个档位对应的目标质量 ID。

- [ ] **Step 2: 运行测试确认失败**

Run: Xcode MCP `RunSomeTests` with target `BilibiliLive-iOSTests` and test identifiers:

- `VideoPlaybackQualityTests/mapsFourQualitiesIntoHighMediumLow()`
- `VideoPlaybackQualityTests/mapsTwoQualitiesIntoHighAndLow()`
- `VideoPlaybackQualityTests/mapsSingleQualityIntoSingleTier()`

Expected: FAIL，因为档位模型与归类逻辑尚不存在。

- [ ] **Step 3: 实现最小档位模型**

在 `BilibiliLive-iOS/Models/VideoPlaybackQuality.swift` 中新增：

- `enum VideoPlaybackQualityTier`，至少包含 `high`、`medium`、`low`
- `struct VideoPlaybackQualityOption`
- 一个从 `[VideoPlayURLInfo.Dash.VideoStream]` 生成档位映射结果的纯逻辑 API

要求：

- 只按当前视频实际返回的唯一质量 ID 动态映射
- 不引入固定 1080P / 720P / 480P 阈值

- [ ] **Step 4: 运行测试确认通过**

Run: Xcode MCP `RunSomeTests` with the 3 tests above.

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add BilibiliLive-iOS/Models/VideoPlaybackQuality.swift BilibiliLive-iOSTests/VideoPlaybackQualityTests.swift
git commit -m "test: cover iOS playback quality tier mapping"
```

### Task 2: 扩展 DASH 选流以支持按档位取流

**Files:**
- Modify: `BilibiliLive-iOS/Utilities/DASHStreamSelection.swift`
- Modify: `BilibiliLive-iOSTests/DASHStreamSelectionTests.swift`
- Modify: `BilibiliLive-iOS/Models/VideoDetailModels.swift` if helper properties are needed for ordered URLs

- [ ] **Step 1: 写出按档位选流与 URL 排序失败测试**

在 `BilibiliLive-iOSTests/DASHStreamSelectionTests.swift` 增加测试，覆盖：

- 选择高档时命中最高质量组
- 选择中档时命中中位质量组
- 选择低档时命中最低质量组
- 同档位内继续优先 AVC
- `baseUrl + backupUrl` 会去重，并把 PCDN URL 排到后面

- [ ] **Step 2: 运行测试确认失败**

Run: Xcode MCP `RunSomeTests` with the new `DASHStreamSelectionTests/...` cases.

Expected: FAIL，因为当前 `DASHStreamSelection.select(from:)` 只支持默认最高画质，也没有显式的 URL 排序规则。

- [ ] **Step 3: 实现最小按档位选流逻辑**

在 `BilibiliLive-iOS/Utilities/DASHStreamSelection.swift` 中：

- 为 `select` 增加目标档位输入
- 用 Task 1 的档位映射结果选出目标质量组
- 保留现有音频优先级逻辑
- 抽出 URL 排序 / 去重 helper，生成 `primaryURL` 与有序 `allURLs`

如有必要，可在 `VideoDetailModels.swift` 增加只服务 iOS 的轻量 helper，但不要把 tvOS 代码直接搬过来。

- [ ] **Step 4: 运行测试确认通过**

Run: Xcode MCP `RunSomeTests` for all `DASHStreamSelectionTests`.

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add BilibiliLive-iOS/Utilities/DASHStreamSelection.swift BilibiliLive-iOSTests/DASHStreamSelectionTests.swift BilibiliLive-iOS/Models/VideoDetailModels.swift
git commit -m "feat: add tier-based DASH stream selection"
```

### Task 3: 让 ViewModel 管理档位状态与切档续播

**Files:**
- Modify: `BilibiliLive-iOS/ViewModels/VideoDetailViewModel.swift`
- Modify: `BilibiliLive-iOS/Utilities/DASHVideoPlayer.swift`
- Modify: `BilibiliLive-iOSTests/VideoDetailPlaybackFlowTests.swift`

- [ ] **Step 1: 写出 ViewModel 档位状态与切档续播失败测试**

在 `BilibiliLive-iOSTests/VideoDetailPlaybackFlowTests.swift` 增加测试，覆盖：

- 首次加载后会暴露可选档位列表
- 默认选中最高可用档位
- 切档时会调用播放器构建逻辑并更新当前档位
- 切换分 P 时会重新计算档位列表

如果续播时间需要抽象，可先通过注入轻量 player facade 或时间读取闭包来保证测试可控。

- [ ] **Step 2: 运行测试确认失败**

Run: Xcode MCP `RunSomeTests` with the new `VideoDetailPlaybackFlowTests/...` cases.

Expected: FAIL，因为当前 ViewModel 不缓存 play info，也没有档位状态。

- [ ] **Step 3: 实现最小 ViewModel / PlayerBuilder 扩展**

在 `BilibiliLive-iOS/ViewModels/VideoDetailViewModel.swift` 中：

- 增加缓存的 `VideoPlayURLInfo`
- 增加可选档位列表、当前档位、切档入口
- 在首次加载与切分 P 后重新计算档位
- 切档时记录当前播放时间并在新播放器创建后恢复

在 `BilibiliLive-iOS/Utilities/DASHVideoPlayer.swift` 中：

- 让 `createPlayer(from:aid:)` 支持接收目标档位
- 用 Task 2 的选流逻辑构造播放器

- [ ] **Step 4: 运行测试确认通过**

Run: Xcode MCP `RunSomeTests` for all `VideoDetailPlaybackFlowTests`.

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add BilibiliLive-iOS/ViewModels/VideoDetailViewModel.swift BilibiliLive-iOS/Utilities/DASHVideoPlayer.swift BilibiliLive-iOSTests/VideoDetailPlaybackFlowTests.swift
git commit -m "feat: add iOS video quality switching state"
```

### Task 4: 接入播放器区域的高 / 中 / 低切换 UI

**Files:**
- Modify: `BilibiliLive-iOS/Views/VideoDetail/VideoPlayerView.swift`
- Modify: `BilibiliLive-iOS/Views/VideoDetail/VideoDetailView.swift`

- [ ] **Step 1: 写出最小交互验收标准**

在计划执行时记录以下手动验收点：

- 播放器区域只展示当前视频实际可选的档位
- 两档视频不展示空的“中”
- 点击档位后会切换选中状态
- 切档过程中播放器区域保持 iOS 现有布局，不引入 tvOS 菜单样式

- [ ] **Step 2: 实现最小 UI**

在 `BilibiliLive-iOS/Views/VideoDetail/VideoPlayerView.swift` 中：

- 为播放器区域增加档位切换入口
- 样式保持 iOS 习惯，可使用轻量 segmented / pill 风格，不照搬 tvOS 菜单

在 `BilibiliLive-iOS/Views/VideoDetail/VideoDetailView.swift` 中：

- 将 ViewModel 提供的档位状态和切换动作接入 `VideoPlayerView`

- [ ] **Step 3: 用 Xcode Preview 或 Build 验证无编译错误**

Run: Xcode MCP `BuildProject` on `windowtab1`.

Expected: BUILD SUCCEEDED，且播放器相关 SwiftUI 视图无新的编译错误。

- [ ] **Step 4: 提交**

```bash
git add BilibiliLive-iOS/Views/VideoDetail/VideoPlayerView.swift BilibiliLive-iOS/Views/VideoDetail/VideoDetailView.swift
git commit -m "feat: add iOS playback quality controls"
```

### Task 5: 为 ResourceLoader 增加自动 CDN 失败切换

**Files:**
- Modify: `BilibiliLive-iOS/Utilities/DASHResourceLoader.swift`
- Modify: `BilibiliLive-iOSTests/DASHResourceLoaderTests.swift`

- [ ] **Step 1: 写出 CDN 轮转失败测试**

在 `BilibiliLive-iOSTests/DASHResourceLoaderTests.swift` 增加测试，覆盖：

- 视频主 URL 失败时会推进到下一条视频 URL
- 音频主 URL 失败时只推进音频 URL
- 失败 URL 不会在同一会话内循环回退
- 候选耗尽时会返回失败状态

为便于测试，可先把“URL 失败后如何推进索引”的策略抽成纯逻辑或注入一个 request executor。

- [ ] **Step 2: 运行测试确认失败**

Run: Xcode MCP `RunSomeTests` for the new `DASHResourceLoaderTests/...` cases.

Expected: FAIL，因为当前 loader 始终只使用 `primaryURL`。

- [ ] **Step 3: 实现最小 CDN 轮转逻辑**

在 `BilibiliLive-iOS/Utilities/DASHResourceLoader.swift` 中：

- 为视频和音频分别维护当前 URL 索引
- 请求失败时只推进对应媒体的索引
- 成功后固定使用当前成功 URL，直到再次失败
- 候选耗尽时向上层返回失败

保持现有 playlist 结构不变，避免同时引入多码率复杂度。

- [ ] **Step 4: 运行测试确认通过**

Run: Xcode MCP `RunSomeTests` for all `DASHResourceLoaderTests`.

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add BilibiliLive-iOS/Utilities/DASHResourceLoader.swift BilibiliLive-iOSTests/DASHResourceLoaderTests.swift
git commit -m "feat: add CDN failover for iOS DASH playback"
```

### Task 6: 全量回归与交付确认

**Files:**
- Modify: only if verification reveals regressions

- [ ] **Step 1: 运行相关单测**

Run: Xcode MCP `RunSomeTests` with:

- `BilibiliLive-iOSTests/VideoPlaybackQualityTests`
- `BilibiliLive-iOSTests/DASHStreamSelectionTests`
- `BilibiliLive-iOSTests/VideoDetailPlaybackFlowTests`
- `BilibiliLive-iOSTests/DASHResourceLoaderTests`

Expected: PASS。

- [ ] **Step 2: 构建 iOS 工程**

Run: Xcode MCP `BuildProject` on `windowtab1`.

Expected: BUILD SUCCEEDED。

- [ ] **Step 3: 进行手动验收**

在模拟器或设备上验证：

- 普通视频详情页默认选中最高档
- 切换高 / 中 / 低后画面可继续播放
- 切档后播放时间基本延续
- 某一主 CDN 失效时，同档位内可自动切到备选 URL
- 当 DASH 全部失败时仍会退回 direct play

- [ ] **Step 4: 汇总结果并准备交付**

记录：

- 实际运行的 Xcode MCP 操作
- 关键测试结果
- 剩余风险，如 AVPlayer 对播中切 CDN 的实际容忍度

- [ ] **Step 5: 提交**

```bash
git add .
git commit -m "feat: improve iOS video quality switching and CDN failover"
```
