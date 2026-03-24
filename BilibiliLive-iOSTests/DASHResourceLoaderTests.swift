import Foundation
import Testing

@testable import BilibiliLive_iOS

struct DASHResourceLoaderTests {
  private func makeLoader(
    videoURLs: [URL] = [URL(string: "https://video/avc.m4s")!],
    audioURLs: [URL] = [URL(string: "https://audio/aac.m4s")!],
    videoSegmentBase: VideoPlayURLInfo.Dash.SegmentBase? = nil,
    audioSegmentBase: VideoPlayURLInfo.Dash.SegmentBase? = nil,
    sidxDownloader: @escaping @Sendable (URL, String) async -> DASHResourceLoader.SidxDownloadResult? = {
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

    #expect(playlist.contains("#EXTINF:1,"))
    #expect(playlist.contains("https://video/avc.m4s"))
  }

  @Test
  func buildsAudioPlaylistThatPointsAtPrimaryAudioURL() throws {
    let loader = makeLoader()
    let playlist = loader.audioPlaylist()

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
    let segmentBase = VideoPlayURLInfo.Dash.SegmentBase(initialization: "0-99", indexRange: "100-199")
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
}
