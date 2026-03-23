import Foundation
import Testing

@testable import BilibiliLive_iOS

struct DASHStreamSelectionTests {
  @Test
  func selectsHighestQualityAvcStreamWhenMultipleCodecsShareQuality() throws {
    let playInfo = VideoPlayURLInfo(
      quality: 80,
      format: nil,
      timelength: nil,
      dash: .init(
        duration: 120,
        video: [
          .init(
            id: 120,
            baseUrl: "https://video/hevc.m4s",
            backupUrl: ["https://backup/video/hevc.m4s"],
            bandwidth: 8_000_000,
            codecid: 12,
            codecs: "hev1.1.6.L150.90"
          ),
          .init(
            id: 120,
            baseUrl: "https://video/avc.m4s",
            backupUrl: ["https://backup/video/avc.m4s"],
            bandwidth: 7_500_000,
            codecid: 7,
            codecs: "avc1.640032"
          ),
        ],
        audio: [
          .init(
            id: 30232,
            baseUrl: "https://audio/aac.m4s",
            backupUrl: ["https://backup/audio/aac.m4s"],
            bandwidth: 132_000
          )
        ]
      ),
      durl: nil
    )

    let selection = try DASHStreamSelection.select(from: playInfo)

    #expect(selection.video.id == 120)
    #expect(selection.video.primaryURL.absoluteString == "https://video/avc.m4s")
    #expect(selection.video.allURLs.count == 2)
  }

  @Test
  func prefersCompatibleAacAudioTrack() throws {
    let playInfo = VideoPlayURLInfo(
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
            id: 30280,
            baseUrl: "https://audio/high.m4s",
            backupUrl: nil,
            bandwidth: 132_000
          ),
          .init(
            id: 30232,
            baseUrl: "https://audio/aac.m4s",
            backupUrl: nil,
            bandwidth: 128_000
          ),
        ]
      ),
      durl: nil
    )

    let selection = try DASHStreamSelection.select(from: playInfo)

    #expect(selection.audio.id == 30232)
    #expect(selection.audio.primaryURL.absoluteString == "https://audio/aac.m4s")
  }

  @Test
  func fallsBackToHevcWhenAvcIsUnavailable() throws {
    let playInfo = VideoPlayURLInfo(
      quality: 80,
      format: nil,
      timelength: nil,
      dash: .init(
        duration: 120,
        video: [
          .init(
            id: 120,
            baseUrl: "https://video/hevc.m4s",
            backupUrl: nil,
            bandwidth: 8_000_000,
            codecid: 12,
            codecs: "hev1.1.6.L150.90"
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

    let selection = try DASHStreamSelection.select(from: playInfo)

    #expect(selection.video.primaryURL.absoluteString == "https://video/hevc.m4s")
  }

  @Test
  func prefersHevcOverAv1WhenNoAvcStreamExists() throws {
    let playInfo = VideoPlayURLInfo(
      quality: 120,
      format: nil,
      timelength: nil,
      dash: .init(
        duration: 120,
        video: [
          .init(
            id: 120,
            baseUrl: "https://video/av1.m4s",
            backupUrl: nil,
            bandwidth: 8_500_000,
            codecid: 13,
            codecs: "av01.0.12M.08"
          ),
          .init(
            id: 120,
            baseUrl: "https://video/hevc.m4s",
            backupUrl: nil,
            bandwidth: 8_000_000,
            codecid: 12,
            codecs: "hev1.1.6.L150.90"
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

    let selection = try DASHStreamSelection.select(from: playInfo)

    #expect(selection.video.primaryURL.absoluteString == "https://video/hevc.m4s")
  }
}
