import Foundation
import Testing

@testable import BilibiliLive_iOS

struct DASHResourceLoaderTests {
  private func makeLoader(
    videoURLs: [URL] = [URL(string: "https://video/avc.m4s")!],
    audioURLs: [URL] = [URL(string: "https://audio/aac.m4s")!],
    videoSegmentBase: VideoPlayURLInfo.Dash.SegmentBase? = nil,
    audioSegmentBase: VideoPlayURLInfo.Dash.SegmentBase? = nil,
    duration: Int = 0,
    sidxDownloader:
      @escaping @Sendable (URL, String) async -> DASHResourceLoader.SidxDownloadResult? = {
        _, _ in nil
      }
  ) -> DASHResourceLoader {
    let video = DASHStreamSelection.SelectedVideo(
      id: 120,
      primaryURL: videoURLs[0],
      allURLs: videoURLs,
      segmentBase: videoSegmentBase
    )
    let audio = DASHStreamSelection.SelectedAudio(
      id: 30232,
      primaryURL: audioURLs[0],
      allURLs: audioURLs,
      segmentBase: audioSegmentBase
    )

    return DASHResourceLoader(
      video: video,
      audio: audio,
      aid: 123,
      duration: duration,
      sidxDownloader: sidxDownloader
    )
  }

  @Test
  func buildsMasterPlaylistWithSingleVideoAndAudioRendition() throws {
    let loader = makeLoader()
    let playlist = loader.masterPlaylist()

    #expect(playlist.contains("#EXTM3U"))
    #expect(playlist.contains("TYPE=AUDIO"))
    #expect(playlist.contains("GROUP-ID=\"audio\""))
    #expect(playlist.contains("stream/video"))
  }

  @Test
  func buildsVideoPlaylistThatPointsAtPrimaryVideoURL() throws {
    let loader = makeLoader()
    let playlist = loader.videoPlaylist()

    // duration=0 时回退为 fallbackTargetDuration (1)
    #expect(playlist.contains("#EXTINF:1,"))
    #expect(playlist.contains("https://video/avc.m4s"))
  }

  @Test
  func buildsAudioPlaylistThatPointsAtPrimaryAudioURL() throws {
    let loader = makeLoader()
    let playlist = loader.audioPlaylist()

    // duration=0 时回退为 fallbackTargetDuration (1)
    #expect(playlist.contains("#EXTINF:1,"))
    #expect(playlist.contains("https://audio/aac.m4s"))
  }

  @Test
  func producesCustomSchemePlaybackURL() {
    let loader = makeLoader()

    #expect(loader.playbackURL.absoluteString.hasPrefix("bilibili-dash://"))
  }

  @Test
  func advancesVideoURLWhenVideoRequestFails() {
    let loader = makeLoader(
      videoURLs: [
        URL(string: "https://video/main.m4s")!,
        URL(string: "https://video/backup.m4s")!,
      ],
      audioURLs: [
        URL(string: "https://audio/main.m4s")!,
        URL(string: "https://audio/backup.m4s")!,
      ]
    )

    let advanced = loader.advanceVideoURLAfterFailure()

    #expect(advanced == true)
    #expect(loader.currentVideoURL == URL(string: "https://video/backup.m4s"))
    #expect(loader.currentAudioURL == URL(string: "https://audio/main.m4s"))
  }

  @Test
  func advancesAudioURLWhenAudioRequestFails() {
    let loader = makeLoader(
      videoURLs: [
        URL(string: "https://video/main.m4s")!,
        URL(string: "https://video/backup.m4s")!,
      ],
      audioURLs: [
        URL(string: "https://audio/main.m4s")!,
        URL(string: "https://audio/backup.m4s")!,
      ]
    )

    let advanced = loader.advanceAudioURLAfterFailure()

    #expect(advanced == true)
    #expect(loader.currentAudioURL == URL(string: "https://audio/backup.m4s"))
    #expect(loader.currentVideoURL == URL(string: "https://video/main.m4s"))
  }

  @Test
  func doesNotCycleBackAfterExhaustingVideoURLs() {
    let loader = makeLoader(
      videoURLs: [
        URL(string: "https://video/main.m4s")!,
        URL(string: "https://video/backup.m4s")!,
      ]
    )

    #expect(loader.advanceVideoURLAfterFailure() == true)
    #expect(loader.advanceVideoURLAfterFailure() == false)
    #expect(loader.currentVideoURL == URL(string: "https://video/backup.m4s"))
  }

  @Test
  func fallsBackToBackupURLWhenPrimarySidxDownloadFails() async {
    let segmentBase = VideoPlayURLInfo.Dash.SegmentBase(
      initialization: "0-99", indexRange: "100-199")
    let loader = makeLoader(
      videoURLs: [
        URL(string: "https://video/main.m4s")!,
        URL(string: "https://video/backup.m4s")!,
      ],
      videoSegmentBase: segmentBase,
      sidxDownloader: { url, _ in
        guard url.absoluteString == "https://video/backup.m4s" else {
          return nil
        }
        return .init(timescale: 1000, segments: [.init(size: 256, duration: 1000)])
      }
    )

    let playlist = await loader.detailedPlaylist(for: loader.video)

    #expect(playlist?.contains("https://video/backup.m4s") == true)
    #expect(loader.currentVideoURL == URL(string: "https://video/backup.m4s"))
  }

  // MARK: - 任务 4.1: simplePlaylist 时长测试

  @Test
  func simplePlaylistUsesActualDurationWhenProvided() {
    let loader = makeLoader(duration: 120)
    let videoPlaylist = loader.videoPlaylist()
    let audioPlaylist = loader.audioPlaylist()

    #expect(videoPlaylist.contains("#EXTINF:120,"))
    #expect(videoPlaylist.contains("#EXT-X-TARGETDURATION:120"))
    #expect(audioPlaylist.contains("#EXTINF:120,"))
    #expect(audioPlaylist.contains("#EXT-X-TARGETDURATION:120"))
  }

  @Test
  func simplePlaylistFallsBackToOneSecondWhenDurationIsZero() {
    let loader = makeLoader(duration: 0)
    let playlist = loader.videoPlaylist()

    #expect(playlist.contains("#EXTINF:1,"))
    #expect(playlist.contains("#EXT-X-TARGETDURATION:1"))
  }

  // MARK: - 任务 4.2: SIDX 重试逻辑测试

  @Test
  func retriesSidxDownloadUpToThreeTimesBeforeFallingBack() async {
    var callCount = 0
    let segmentBase = VideoPlayURLInfo.Dash.SegmentBase(
      initialization: "0-99", indexRange: "100-199")
    let loader = makeLoader(
      videoSegmentBase: segmentBase,
      sidxDownloader: { _, _ in
        callCount += 1
        return nil  // 始终返回 nil ，触发所有重试
      }
    )

    let playlist = await loader.detailedPlaylist(for: loader.video)

    // SIDX 不可用，detailedPlaylist 返回 nil
    #expect(playlist == nil)
    // 应该尝试 3 次（一个 URL 不用切换）
    #expect(callCount == 3)
  }

  @Test
  func succeedsOnSecondSidxRetryWithoutAdvancingURL() async {
    var callCount = 0
    let segmentBase = VideoPlayURLInfo.Dash.SegmentBase(
      initialization: "0-99", indexRange: "100-199")
    let loader = makeLoader(
      videoSegmentBase: segmentBase,
      sidxDownloader: { _, _ in
        callCount += 1
        guard callCount >= 2 else { return nil }  // 第二次成功
        return .init(timescale: 1000, segments: [.init(size: 512, duration: 2000)])
      }
    )

    let playlist = await loader.detailedPlaylist(for: loader.video)

    // 第二次重试成功，播放列表应就绪
    #expect(playlist != nil)
    // 不需要切换 URL
    #expect(loader.currentVideoURL == URL(string: "https://video/avc.m4s"))
  }
}
