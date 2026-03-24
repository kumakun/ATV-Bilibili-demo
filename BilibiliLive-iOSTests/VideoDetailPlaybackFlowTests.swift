import AVFoundation
import Foundation
import Testing

@testable import BilibiliLive_iOS

@MainActor
struct VideoDetailPlaybackFlowTests {
  @Test
  func usesDashPlayerWhenDashBuilderSucceeds() async throws {
    let expectedPlayer = AVPlayer()
    let requestedTiers = RequestedTierRecorder()
    let viewModel = VideoDetailViewModel(
      aid: 1,
      cid: 2,
      playURLLoader: VideoPlayURLLoading(
        requestPlayURL: { _, _ in makeDashPlayURLInfo() },
        requestDirectPlayURL: { _, _ in makeDirectPlayInfo() }
      ),
      playerBuilder: VideoPlayerBuilding(
        makeDashPlayer: { _, _, tier in
          await requestedTiers.record(tier)
          return expectedPlayer
        },
        makeDirectPlayer: { _, _ in AVPlayer() }
      )
    )

    await viewModel.loadPlayUrl(forceReload: true)

    #expect(viewModel.player === expectedPlayer)
    #expect(viewModel.errorMessage == nil)
    #expect(viewModel.availablePlaybackQualities.map(\.tier) == [.high])
    #expect(viewModel.selectedPlaybackQuality == .high)
    #expect(await requestedTiers.values == [.high])
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
        makeDashPlayer: { _, _, _ in nil },
        makeDirectPlayer: { _, _ in expectedPlayer }
      )
    )

    await viewModel.loadPlayUrl(forceReload: true)

    #expect(viewModel.player === expectedPlayer)
    #expect(viewModel.playURL?.absoluteString == "https://direct/video.mp4")
    #expect(viewModel.errorMessage == nil)
  }

  @Test
  func switchesToRequestedQualityTier() async throws {
    let requestedTiers = RequestedTierRecorder()
    let viewModel = VideoDetailViewModel(
      aid: 1,
      cid: 2,
      playURLLoader: VideoPlayURLLoading(
        requestPlayURL: { _, _ in makeMultiTierDashPlayURLInfo() },
        requestDirectPlayURL: { _, _ in makeDirectPlayInfo() }
      ),
      playerBuilder: VideoPlayerBuilding(
        makeDashPlayer: { _, _, tier in
          await requestedTiers.record(tier)
          return AVPlayer()
        },
        makeDirectPlayer: { _, _ in AVPlayer() }
      )
    )

    await viewModel.loadPlayUrl(forceReload: true)
    await viewModel.switchPlaybackQuality(to: .low)

    #expect(viewModel.availablePlaybackQualities.map(\.tier) == [.high, .medium, .low])
    #expect(viewModel.selectedPlaybackQuality == .low)
    #expect(await requestedTiers.values == [.high, .low])
  }

  @Test
  func recalculatesPlaybackQualitiesWhenEpisodeChanges() async throws {
    let requestedTiers = RequestedTierRecorder()
    let playInfoByCID = [
      2: makeMultiTierDashPlayURLInfo(),
      3: makeDashPlayURLInfo(),
    ]
    let viewModel = VideoDetailViewModel(
      aid: 1,
      cid: 2,
      playURLLoader: VideoPlayURLLoading(
        requestPlayURL: { _, cid in
          guard let info = playInfoByCID[cid] else {
            Issue.record("Unexpected CID \(cid)")
            return makeDashPlayURLInfo()
          }
          return info
        },
        requestDirectPlayURL: { _, _ in makeDirectPlayInfo() }
      ),
      playerBuilder: VideoPlayerBuilding(
        makeDashPlayer: { _, _, tier in
          await requestedTiers.record(tier)
          return AVPlayer()
        },
        makeDirectPlayer: { _, _ in AVPlayer() }
      )
    )
    viewModel.pages = [
      VideoPage(cid: 2, page: 1, epid: nil, from: "vupload", part: "P1"),
      VideoPage(cid: 3, page: 2, epid: nil, from: "vupload", part: "P2"),
    ]

    await viewModel.loadPlayUrl(forceReload: true)
    #expect(viewModel.availablePlaybackQualities.map(\.tier) == [.high, .medium, .low])

    await viewModel.switchEpisode(to: 1)

    #expect(viewModel.currentPageIndex == 1)
    #expect(viewModel.availablePlaybackQualities.map(\.tier) == [.high])
    #expect(viewModel.selectedPlaybackQuality == .high)
    #expect(await requestedTiers.values == [.high, .high])
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

  private func makeMultiTierDashPlayURLInfo() -> VideoPlayURLInfo {
    VideoPlayURLInfo(
      quality: 120,
      format: nil,
      timelength: nil,
      dash: .init(
        duration: 120,
        video: [
          .init(
            id: 120,
            baseUrl: "https://video/120-avc.m4s",
            backupUrl: nil,
            bandwidth: 8_000_000,
            codecid: 7,
            codecs: "avc1.640032"
          ),
          .init(
            id: 64,
            baseUrl: "https://video/64-avc.m4s",
            backupUrl: nil,
            bandwidth: 4_000_000,
            codecid: 7,
            codecs: "avc1.4d4028"
          ),
          .init(
            id: 32,
            baseUrl: "https://video/32-avc.m4s",
            backupUrl: nil,
            bandwidth: 1_500_000,
            codecid: 7,
            codecs: "avc1.4d401f"
          ),
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

  actor RequestedTierRecorder {
    private(set) var values = [VideoPlaybackQualityTier]()

    func record(_ tier: VideoPlaybackQualityTier) {
      values.append(tier)
    }
  }
}
