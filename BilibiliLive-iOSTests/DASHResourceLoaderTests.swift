import Foundation
import Testing

@testable import BilibiliLive_iOS

struct DASHResourceLoaderTests {
  private func makeLoader() -> DASHResourceLoader {
    let video = DASHStreamSelection.SelectedVideo(
      id: 120,
      primaryURL: URL(string: "https://video/avc.m4s")!,
      allURLs: [URL(string: "https://video/avc.m4s")!]
    )
    let audio = DASHStreamSelection.SelectedAudio(
      id: 30232,
      primaryURL: URL(string: "https://audio/aac.m4s")!,
      allURLs: [URL(string: "https://audio/aac.m4s")!]
    )

    return DASHResourceLoader(video: video, audio: audio, aid: 123)
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
}
