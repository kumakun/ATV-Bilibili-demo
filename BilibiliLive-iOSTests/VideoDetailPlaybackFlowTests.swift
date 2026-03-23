import AVFoundation
import Foundation
import Testing

@testable import BilibiliLive_iOS

@MainActor
struct VideoDetailPlaybackFlowTests {
  @Test
  func usesDashPlayerWhenDashBuilderSucceeds() async throws {
    let expectedPlayer = AVPlayer()
    let viewModel = VideoDetailViewModel(
      aid: 1,
      cid: 2,
      playURLLoader: VideoPlayURLLoading(
        requestPlayURL: { _, _ in makeDashPlayURLInfo() },
        requestDirectPlayURL: { _, _ in makeDirectPlayInfo() }
      ),
      playerBuilder: VideoPlayerBuilding(
        makeDashPlayer: { _, _ in expectedPlayer },
        makeDirectPlayer: { _, _ in AVPlayer() }
      )
    )

    await viewModel.loadPlayUrl(forceReload: true)

    #expect(viewModel.player === expectedPlayer)
    #expect(viewModel.errorMessage == nil)
  }

  @Test
  func fallsBackToDirectPlayerWhenDashBuilderReturnsNil() async throws {
    let expectedPlayer = AVPlayer()
    let viewModel = VideoDetailViewModel(
      aid: 1,
      cid: 2,
      playURLLoader: VideoPlayURLLoading(
        requestPlayURL: { _, _ in makeDashPlayURLInfo() },
        requestDirectPlayURL: { _, _ in makeDirectPlayInfo() }
      ),
      playerBuilder: VideoPlayerBuilding(
        makeDashPlayer: { _, _ in nil },
        makeDirectPlayer: { _, _ in expectedPlayer }
      )
    )

    await viewModel.loadPlayUrl(forceReload: true)

    #expect(viewModel.player === expectedPlayer)
    #expect(viewModel.playURL?.absoluteString == "https://direct/video.mp4")
    #expect(viewModel.errorMessage == nil)
  }

  private func makeDashPlayURLInfo() -> VideoPlayURLInfo {
    VideoPlayURLInfo(
      quality: 120,
      format: nil,
      timelength: nil,
      dash: .init(
        duration: 120,
        video: [
          .init(
            id: 120,
            baseUrl: "https://video/avc.m4s",
            backupUrl: nil,
            bandwidth: 8_000_000,
            codecid: 7,
            codecs: "avc1.640032"
          )
        ],
        audio: [
          .init(
            id: 30232,
            baseUrl: "https://audio/aac.m4s",
            backupUrl: nil,
            bandwidth: 132_000
          )
        ]
      ),
      durl: nil
    )
  }

  private func makeDirectPlayInfo() -> VideoPlayURLInfo {
    VideoPlayURLInfo(
      quality: 64,
      format: "mp4",
      timelength: nil,
      dash: nil,
      durl: [
        .init(
          url: "https://direct/video.mp4",
          backupUrl: ["https://backup/direct/video.mp4"]
        )
      ]
    )
  }
}
