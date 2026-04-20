## 上下文

iOS 项目使用 `DASHResourceLoader` 将 DASH 流（分离的音视频 URL）转换为 HLS 播放列表，通过自定义 `AVAssetResourceLoaderDelegate` 拦截请求并返回生成的 m3u8。当前实现有两条路径：

1. **detailedPlaylist**：下载 SIDX box → 解析 segment 索引 → 生成带 `#EXT-X-BYTERANGE` 的 VOD 播放列表（seek 正常）
2. **simplePlaylist**（回退）：将整个文件作为单个 1 秒 segment，无 byte-range（seek 失败）

当 SIDX 下载因网络问题失败时，走回退路径，AVPlayer seek 后从头播放。

## 目标 / 非目标

**目标：**
- 用户拖动进度条后，视频从目标位置继续播放，无论 SIDX 是否可用
- 提高 SIDX 下载成功率

**非目标：**
- 不重写整个 DASH→HLS 转换架构
- 不实现自适应码率切换（ABR）

## 决策

### 1. 回退播放列表使用实际时长而非 1 秒

**选择**：将 `simplePlaylist` 的 `TARGETDURATION` 和 `EXTINF` 设为视频实际时长（从 DASH manifest 中已知）。

**替代方案**：
- 将整个文件拆分为多个固定 byte-range segment → 复杂度高，不知道关键帧位置
- 不使用 HLS 回退，直接用 AVURLAsset 播放 MP4 URL → 无法统一音视频分离流的处理

**理由**：AVPlayer 对 VOD 单 segment 播放列表在 `EXTINF` 与实际时长匹配时能正确 seek（通过 HTTP Range 请求）。1 秒的错误值导致 seek 计算偏差。

### 2. 启用精确时长

**选择**：将 `AVURLAssetPreferPreciseDurationAndTimingKey` 设为 `true`。

**理由**：对于点播视频，精确时长对 seek 精度至关重要，性能代价（首次加载多下载少量数据）可接受。

### 3. SIDX 下载增加重试

**选择**：失败后最多重试 2 次（共 3 次尝试），每次超时 10 秒。

**替代方案**：
- 无限重试 → 阻塞播放启动
- 不重试直接回退 → 现状，体验差

## 风险 / 权衡

- [风险] 精确时长模式增加首次加载延迟 → 对于大多数视频（< 1h）影响 < 200ms，可接受
- [风险] 回退播放列表单 segment 仍可能在极长视频上 seek 不精确 → 可通过后续迭代改进，但比从头播放好很多
