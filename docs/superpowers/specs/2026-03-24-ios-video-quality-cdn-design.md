# iOS 普通视频多档清晰度与自动 CDN 兜底设计

**日期：** 2026-03-24

## 目标

为 `BilibiliLive-iOS/` 的普通视频播放补齐两项能力：

- 基于当前视频实际可用流，自动归类并支持高 / 中 / 低三档清晰度切换。
- 在用户已选档位内，对 `baseUrl + backupUrl` 做自动 CDN 失败切换，提升起播与播放稳定性。

## 范围

- 仅修改 iOS 项目，不抽共享代码，不改 tvOS 现有实现。
- 保持当前 `VideoDetailView` 与 `AVPlayerViewController` 的主体结构。
- 用户可手动切换高 / 中 / 低清晰度。
- CDN 只做自动兜底，不提供手动切换入口。
- 保留现有 direct play fallback 作为最终回退链路。

## 非目标

- 不把 tvOS 播放器插件体系整体迁入 iOS。
- 不暴露具体 `qn`、编码格式或 CDN 名称给用户。
- 不做自动降档播放。
- 不做全局 CDN 健康状态缓存或持久化。
- 不扩展字幕、多音轨、弹幕或杜比相关能力。

## 设计概览

本次改造分为三层：

1. 档位归类层
   - 从 `VideoPlayURLInfo.dash.video` 中提取当前视频可用画质集合。
   - 将唯一画质等级按从高到低排序，并自动映射成高 / 中 / 低档位。

2. 播放选择层
   - 根据当前选中的档位，选择该档位内最合适的视频流与音频流。
   - 视频流继续保持兼容性优先，优先 AVC，其次 HEVC，再次其它编码。

3. CDN 兜底层
   - 对已选视频流和音频流分别构建主备 URL 候选列表。
   - 当某个媒体资源请求失败时，仅轮转该媒体自己的 CDN 候选，自动重试。

## 档位归类规则

清晰度档位不使用固定分辨率阈值，而是按当前视频返回的可用流动态归类。

规则如下：

- 对 `dash.video` 先按 `id` 分组；每个 `id` 代表一个唯一画质等级。
- 将唯一画质等级按从高到低排序。
- 根据排序结果映射档位：
  - 只有 1 个画质等级时，只显示 1 个档位。
  - 有 2 个画质等级时，只显示高、低两档。
  - 有 3 个及以上画质等级时，高 = 最高档，中 = 中位档，低 = 最低档。
- 每个档位内部可能仍有多个编码流，播放时按兼容性优先规则继续选择具体流。

示例：

- `[120, 80, 64, 32]` -> 高 = `120`，中 = `64`，低 = `32`
- `[80, 64, 32]` -> 高 = `80`，中 = `64`，低 = `32`
- `[120, 80]` -> 高 = `120`，低 = `80`
- `[64]` -> 单档可播

## 状态与交互设计

### ViewModel 职责

`VideoDetailViewModel` 增加以下职责：

- 保存最近一次成功请求的 `VideoPlayURLInfo`
- 暴露当前视频的可选档位列表
- 保存当前选中的档位
- 处理用户切换档位时的播放器重建与续播

### 首次播放

- 进入详情页后继续请求最高能力的 `playurl`。
- 请求成功后，根据当前 `dash.video` 生成档位列表。
- 默认选中当前视频的最高可用档位。
- 按选中档位创建 DASH 播放器。

### 用户切换档位

- 先读取当前播放时间。
- 使用缓存的 `VideoPlayURLInfo` 和目标档位重新选流。
- 重新构建 `AVPlayer` 与对应 resource loader。
- seek 回切换前的播放位置并继续播放。

### 切换分 P

- 保留现有 `switchEpisode(to:)` 主流程。
- 新分 P 重新请求 `playurl`，并重新计算该分 P 自己的档位列表。
- 默认选中新的最高可用档位，不沿用上一个分 P 的绝对 `qn`。

## 选流设计

建议将当前 `DASHStreamSelection` 从“默认选择最高画质”扩展为“基于档位选择目标流”。

扩展后能力：

- 输入 `VideoPlayURLInfo` 与目标档位。
- 输出已选视频流、已选音频流，以及各自有序的主备 URL 列表。

选择规则：

- 视频：
  - 只在目标档位对应的质量组内挑选。
  - 优先 AVC。
  - 没有 AVC 时优先 HEVC。
  - 都没有时退回该组第一个可用流。
- 音频：
  - 延续当前 AAC 类音轨优先策略。
  - 缺失时退回第一条普通音频流。

## CDN 自动兜底设计

### URL 候选列表

对视频流和音频流分别构建：

- `primaryURL`
- `allURLs`

其中 `allURLs` 由 `baseUrl + backupUrl` 排序、去重后得到。

排序参考 tvOS 现有思路：

- 优先官方或更稳定来源。
- 将明显的 PCDN 链接排在更后面。

### 失败切换规则

- `DASHResourceLoader` 在请求 playlist 或后续媒体数据时，如果当前 URL 网络失败、超时或返回不可用响应，则判定当前 CDN 失效。
- 视频失败时只轮转视频候选 URL。
- 音频失败时只轮转音频候选 URL。
- 切换到下一条 URL 后，重试当前请求。
- 一旦某个新 URL 请求成功，后续同媒体请求继续使用该 URL，直到再次失败。

### 边界与终止条件

- 同一会话内，失败过的 URL 不立即回退重试。
- 候选列表只单向前进，不形成循环。
- 当某个媒体的 URL 候选全部耗尽时，认为当前档位的 DASH 播放构建或续播失败。
- 仅在整个 DASH 链路失败后，才退回现有 direct play fallback。

## 文件落点

### 主要修改

- `BilibiliLive-iOS/ViewModels/VideoDetailViewModel.swift`
- `BilibiliLive-iOS/Utilities/DASHStreamSelection.swift`
- `BilibiliLive-iOS/Utilities/DASHResourceLoader.swift`
- `BilibiliLive-iOS/Utilities/DASHVideoPlayer.swift`
- `BilibiliLive-iOS/Views/VideoDetail/VideoPlayerView.swift`
- `BilibiliLive-iOS/Views/VideoDetail/VideoDetailView.swift`

### 建议新增

- 一个 iOS 专用的档位模型文件，用于描述高 / 中 / 低档位与映射结果
- 与档位归类、切换流程、CDN 轮转对应的测试代码

## 测试策略

### 策略层测试

- 验证 1 档、2 档、3 档、4 档以上输入时的档位归类结果
- 验证高 / 中 / 低档位选择到的目标质量组是否正确
- 验证同档位下 AVC 优先、HEVC 次之
- 验证 URL 候选排序、去重与 PCDN 后置规则

### ViewModel 流程测试

- 首次加载后能生成可选档位列表
- 切换档位时会重建播放器
- 切档后能恢复原播放进度
- 切换分 P 后会重新计算新分 P 的档位
- DASH 构建失败时仍能回退 direct play

### ResourceLoader / CDN 兜底测试

- 视频主 URL 失败后会切到下一条视频候选 URL
- 音频主 URL 失败后会切到下一条音频候选 URL
- 视频失败不会误切音频，音频失败不会误切视频
- 候选耗尽时能正确向上层返回失败

## 验收标准

- iOS 普通视频详情页可展示并切换高 / 中 / 低档位
- 档位来自当前视频实际可用流，而非固定分辨率阈值
- 切换档位后能尽量保持原播放位置
- 同一档位内，主 CDN 失败时可自动切换到备选 URL
- 所有候选耗尽后，仍能回退到现有 direct play fallback
- 相关 iOS 单元测试通过，`BilibiliLive-iOS` 可正常构建
