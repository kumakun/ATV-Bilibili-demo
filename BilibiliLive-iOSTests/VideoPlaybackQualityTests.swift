import Foundation
import Testing

@testable import BilibiliLive_iOS

struct VideoPlaybackQualityTests {
  @Test
  func mapsFourQualitiesIntoHighMediumLow() {
    let options = VideoPlaybackQualityOption.makeOptions(from: [
      makeVideoStream(id: 120),
      makeVideoStream(id: 80),
      makeVideoStream(id: 64),
      makeVideoStream(id: 32),
    ])

    #expect(options.map(\.tier) == [.high, .medium, .low])
    #expect(options.map(\.qualityID) == [120, 64, 32])
  }

  @Test
  func mapsTwoQualitiesIntoHighAndLow() {
    let options = VideoPlaybackQualityOption.makeOptions(from: [
      makeVideoStream(id: 120),
      makeVideoStream(id: 80),
    ])

    #expect(options.map(\.tier) == [.high, .low])
    #expect(options.map(\.qualityID) == [120, 80])
  }

  @Test
  func mapsSingleQualityIntoSingleTier() {
    let options = VideoPlaybackQualityOption.makeOptions(from: [
      makeVideoStream(id: 64)
    ])

    #expect(options.map(\.tier) == [.high])
    #expect(options.map(\.qualityID) == [64])
  }

  private func makeVideoStream(id: Int) -> VideoPlayURLInfo.Dash.VideoStream {
    .init(
      id: id,
      baseUrl: "https://video/\(id).m4s",
      backupUrl: nil,
      bandwidth: id * 1000,
      codecid: 7,
      codecs: "avc1.640032"
    )
  }
}
