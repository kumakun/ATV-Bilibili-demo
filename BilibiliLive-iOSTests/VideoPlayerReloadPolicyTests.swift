//
//  VideoPlayerReloadPolicyTests.swift
//  BilibiliLive-iOSTests
//
//  Created by Codex on 2026/3/23.
//

import Testing
@testable import BilibiliLive_iOS

struct VideoPlayerReloadPolicyTests {

  @Test
  func reusesExistingPlayerForSameEpisode() {
    let shouldReload = VideoPlayerReloadPolicy.shouldReloadPlayer(
      currentPlayerCID: 1001,
      requestedCID: 1001,
      hasPlayer: true,
      forceReload: false
    )

    #expect(shouldReload == false)
  }

  @Test
  func reloadsWhenEpisodeChanges() {
    let shouldReload = VideoPlayerReloadPolicy.shouldReloadPlayer(
      currentPlayerCID: 1001,
      requestedCID: 1002,
      hasPlayer: true,
      forceReload: false
    )

    #expect(shouldReload)
  }

  @Test
  func reloadsWhenForcedEvenForSameEpisode() {
    let shouldReload = VideoPlayerReloadPolicy.shouldReloadPlayer(
      currentPlayerCID: 1001,
      requestedCID: 1001,
      hasPlayer: true,
      forceReload: true
    )

    #expect(shouldReload)
  }
}
