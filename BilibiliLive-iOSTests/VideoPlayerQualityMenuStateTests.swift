import Testing

@testable import BilibiliLive_iOS

struct VideoPlayerQualityMenuStateTests {
  @Test
  func showsCurrentSelectedTierInTitle() {
    let state = VideoPlayerQualityMenuState(
      availablePlaybackQualities: [
        VideoPlaybackQualityOption(tier: .high, qualityID: 120),
        VideoPlaybackQualityOption(tier: .medium, qualityID: 64),
        VideoPlaybackQualityOption(tier: .low, qualityID: 32),
      ],
      selectedPlaybackQuality: .medium
    )

    #expect(state.title == "画质·中")
    #expect(state.isEnabled == true)
    #expect(state.style == .accented)
  }

  @Test
  func usesDisabledDarkStyleWhenOnlyOneTierIsAvailable() {
    let state = VideoPlayerQualityMenuState(
      availablePlaybackQualities: [
        VideoPlaybackQualityOption(tier: .high, qualityID: 64)
      ],
      selectedPlaybackQuality: .high
    )

    #expect(state.title == "画质·高")
    #expect(state.isEnabled == false)
    #expect(state.style == .dimmed)
  }
}
