## 1. 回退播放列表修复

- [x] 1.1 修改 `DASHResourceLoader.simplePlaylist()` 接受视频实际时长参数，将 EXTINF 和 TARGETDURATION 设为实际时长
- [x] 1.2 确保调用 `simplePlaylist()` 时传入正确的视频时长（从 DASH manifest 或播放信息中获取）

## 2. SIDX 下载重试

- [x] 2.1 在 SIDX 下载逻辑中添加重试机制，最多 3 次尝试，每次超时 10 秒
- [x] 2.2 仅当所有重试失败后才调用 `simplePlaylist()` 回退

## 3. Asset 配置

- [x] 3.1 将 `DASHVideoPlayer` 中 `AVURLAssetPreferPreciseDurationAndTimingKey` 从 `false` 改为 `true`

## 4. 验证

- [x] 4.1 编写单元测试验证 `simplePlaylist()` 输出的 EXTINF 等于传入时长
- [x] 4.2 编写单元测试验证 SIDX 下载重试逻辑（mock 网络失败场景）
