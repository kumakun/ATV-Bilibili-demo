## 为什么

iOS 视频播放器使用 DASH 资源加载器将 DASH 流转换为 HLS 播放列表。当 SIDX（Segment Index Box）下载失败时，回退到 `simplePlaylist()` ——该方法将整个视频文件生成为单个 1 秒 segment，不包含 byte-range 信息。AVPlayer 在这种播放列表上 seek 时无法正确定位，导致拖动进度条后视频从头重新播放。

## 变更内容

- 修改 `DASHResourceLoader` 的回退播放列表生成逻辑，使其即使在 SIDX 不可用时也能支持 seek
- 增强 SIDX 下载的可靠性（重试、超时处理）
- 将 `AVURLAssetPreferPreciseDurationAndTimingKey` 设为 `true` 以获取精确时长和定位

## 功能 (Capabilities)

### 新增功能

（无）

### 修改功能

- `ios-video-player`: seek 行为需要在 SIDX 可用和不可用两种场景下都能正确工作，不再出现回退到起点的情况

## 影响

- `DASHResourceLoader.swift` — 播放列表生成逻辑
- `DASHVideoPlayer.swift` — asset 配置
- 不影响公共 API，不涉及破坏性变更
