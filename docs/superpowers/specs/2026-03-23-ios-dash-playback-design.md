# iOS 普通视频 DASH 播放首版设计

## 背景

当前 iOS 项目的普通视频播放虽然已经能请求到 B 站 `playurl`，但实际播放链路仍然偏简化，主要依赖直接创建 `AVPlayer` 或使用 `AVMutableComposition` 拼接远程音视频流。相比 tvOS，iOS 侧还缺少一层针对 B 站 DASH 音视频分离资源的稳定适配。

本设计的目标不是把 tvOS 的完整播放器体系迁入 iOS，而是在不改动现有 SwiftUI 页面结构的前提下，先为 iOS 项目补齐“普通视频优先使用 DASH 音视频分离流播放”的基础能力。

## 目标

- 为普通视频提供稳定的 DASH 音视频分离播放能力。
- 保持 iOS 现有页面、ViewModel 与 `AVPlayerViewController` 集成方式不变。
- 在 DASH 构建失败时自动回退到现有 direct play 播放链路。
- 为后续扩展字幕、画质切换、多音轨预留清晰边界。

## 非目标

- 不迁移 tvOS 的完整插件式播放器框架。
- 不实现手动画质切换。
- 不实现自适应多码率策略。
- 不实现字幕、章节、弹幕遮罩。
- 不接入杜比、无损、多音轨能力。
- 不增强番剧、区域限制或直播播放能力。

## 总体方案

iOS 首版采用“精简版 `AVAssetResourceLoaderDelegate`”方案。

上层仍由 `VideoDetailViewModel` 负责请求普通视频 `playurl` 并驱动 UI。底层新增 iOS 专用 DASH 资源加载器，将已选中的一路视频流和一路音频流包装成极简 HLS playlist，再交给 `AVPlayer` 播放。

相比继续使用远程 `AVMutableComposition` 拼接，该方案更接近 tvOS 的成熟思路，同时又能控制范围，仅保留首版真正需要的能力。

## 架构边界

### 1. ViewModel 层

`VideoDetailViewModel` 继续负责：

- 请求普通视频 `playurl`
- 决定优先走 DASH 还是 direct fallback
- 管理 `AVPlayer` 生命周期
- 向 UI 暴露播放状态与错误信息

它不负责 DASH 选流细节，也不直接拼接 playlist。

### 2. DASH 选流层

新增独立的流选择组件，负责：

- 从 `VideoPlayURLInfo` 中选出一条视频流
- 从普通 DASH 音频中选出一条音频流
- 汇总主 URL 与备份 URL
- 产出供资源加载器与播放器工厂使用的统一结构

这样可以把“选哪条流”做成纯逻辑，便于单测。

### 3. DASH 资源加载层

新增 iOS 专用 `AVAssetResourceLoaderDelegate`，负责：

- 维护自定义 scheme
- 生成极简 HLS master playlist
- 生成对应的视频 / 音频 media playlist
- 在 `AVPlayer` 请求自定义 URL 时返回对应 playlist 内容

首版只支持单视频流 + 单音频流，不处理字幕与多码率。

### 4. Player 工厂层

保留 `DASHVideoPlayer` 作为播放器工厂，负责：

- 调用选流组件
- 构造绑定了 resource loader 的 `AVURLAsset`
- 创建 `AVPlayerItem` 与 `AVPlayer`
- 统一注入 `Referer` / `User-Agent`
- 保留 direct play fallback 创建逻辑

## 文件设计

### 新增文件

#### `BilibiliLive-iOS/Utilities/DASHStreamSelection.swift`

职责：

- 封装视频与音频流选择规则
- 产出首版播放所需的已选流对象
- 对外暴露纯逻辑 API，供单测直接调用

#### `BilibiliLive-iOS/Utilities/DASHResourceLoader.swift`

职责：

- 实现 iOS 专用 `AVAssetResourceLoaderDelegate`
- 构建并返回 master playlist / media playlist
- 维护自定义 URL 映射

### 修改文件

#### `BilibiliLive-iOS/Utilities/DASHVideoPlayer.swift`

调整为播放器工厂：

- 调用 `DASHStreamSelection`
- 构造绑定 resource loader 的 `AVURLAsset`
- 创建 `AVPlayer`
- 保留 direct play fallback 能力

不再以远程 `AVMutableComposition` 作为首版 DASH 主实现。

#### `BilibiliLive-iOS/ViewModels/VideoDetailViewModel.swift`

职责保持不变，但需要调整播放构建流程：

- 请求 `playurl`
- 优先创建 DASH 播放器
- 失败时自动退回 direct play
- 增加更明确的日志与错误归因

## 首版行为规则

### 视频流选择

- 先按画质分组
- 优先选择最高可用画质
- 同一画质下优先 AVC / H.264
- 没有 AVC 时再回退 HEVC

### 音频流选择

- 仅使用普通 DASH 音频
- 优先选择兼容性较高的 AAC 类音轨
- 若首选音轨缺失，则退回第一条普通音频流

### URL 策略

- 已选流必须同时保留 `baseUrl` 与 `backupUrl`
- 构建阶段优先主 URL
- 允许对 URL 进行简单排序，尽量优先稳定来源
- 首版不做运行时自动切换 CDN

### 请求头策略

所有实际远程资源访问统一附带：

- `Referer`
- `User-Agent`

以保持与当前 iOS / tvOS 请求行为一致，降低防盗链导致的播放失败概率。

## 数据流

1. `VideoDetailViewModel` 请求普通视频 `playurl`
2. `DASHVideoPlayer` 调用 `DASHStreamSelection` 选出一路视频和一路音频
3. `DASHVideoPlayer` 创建自定义 scheme 的 `AVURLAsset`
4. `DASHResourceLoader` 为该 asset 提供 master playlist 与 media playlist
5. `AVPlayer` 消费虚拟 playlist 并播放真实远程 DASH 资源
6. 若任一步骤失败，则自动退回 direct play

## 错误处理与回退策略

出现以下任一情况时，直接退回现有 direct play 链路：

- `playurl` 中不存在 `dash`
- 无法选出视频流
- 无法选出音频流
- 自定义 `AVURLAsset` 不可播
- `AVPlayerItem` 创建或加载失败

回退目标是确保“DASH 不稳定时，用户至少仍可播放”，避免首版改造导致黑屏或卡死。

## 测试策略

### 自动化测试

新增到 iOS 测试 target：

1. `DASHStreamSelection` 单测
   - 最高画质优先
   - 同画质 AVC 优先于 HEVC
   - 无 AVC 时回退 HEVC
   - 音频优先选择兼容性更高的普通音轨

2. `DASHResourceLoader` playlist 生成单测
   - 生成合法 master playlist
   - 生成合法单视频 / 单音频 media playlist
   - playlist 中包含预期 URL 与关键字段

3. 如有必要，补充回退判定单测
   - DASH 构建失败时退回 direct play

### 人工验收

使用 Xcode MCP 完成：

1. 构建 `BilibiliLive-iOS`
2. 运行新增单测
3. 打开普通视频详情页并验证可正常起播
4. 确认正常场景优先走 DASH 路径
5. 确认异常场景可自动回退 direct play

## 验收标准

- 普通视频默认优先尝试 DASH 音视频分离播放
- DASH 选流规则符合 AVC / AAC 优先策略
- DASH 构建失败时会自动回退 direct play
- iOS 工程可构建通过，新增相关测试通过

## 后续扩展方向

首版完成后，可在当前边界上继续扩展：

- 引入多码率 playlist，支持更接近 tvOS 的画质能力
- 接入字幕 playlist 与字幕资源转换
- 补充多音轨、杜比 / 无损音频能力
- 将更多播放增强逻辑逐步迁入 iOS
