import Foundation

enum VideoPlaybackQualityTier: Int, CaseIterable, Equatable {
  case high
  case medium
  case low

  var title: String {
    switch self {
    case .high:
      "高"
    case .medium:
      "中"
    case .low:
      "低"
    }
  }
}

struct VideoPlaybackQualityOption: Equatable, Identifiable {
  let tier: VideoPlaybackQualityTier
  let qualityID: Int

  var id: VideoPlaybackQualityTier { tier }

  static func makeOptions(from streams: [VideoPlayURLInfo.Dash.VideoStream]) -> [VideoPlaybackQualityOption] {
    let qualityIDs = Array(Set(streams.map(\.id))).sorted(by: >)

    switch qualityIDs.count {
    case 0:
      return []
    case 1:
      return [
        VideoPlaybackQualityOption(tier: .high, qualityID: qualityIDs[0])
      ]
    case 2:
      return [
        VideoPlaybackQualityOption(tier: .high, qualityID: qualityIDs[0]),
        VideoPlaybackQualityOption(tier: .low, qualityID: qualityIDs[1]),
      ]
    default:
      return [
        VideoPlaybackQualityOption(tier: .high, qualityID: qualityIDs[0]),
        VideoPlaybackQualityOption(tier: .medium, qualityID: qualityIDs[qualityIDs.count / 2]),
        VideoPlaybackQualityOption(tier: .low, qualityID: qualityIDs[qualityIDs.count - 1]),
      ]
    }
  }
}
