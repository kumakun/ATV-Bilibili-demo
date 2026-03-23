//
//  VideoPlayerFullscreenTransitionHandlerTests.swift
//  BilibiliLive-iOSTests
//
//  Created by Codex on 2026/3/23.
//

import Testing
@testable import BilibiliLive_iOS

@MainActor
struct VideoPlayerFullscreenTransitionHandlerTests {

  @Test
  func beginFullscreenRequestsLandscapeOrientation() {
    let orientationController = OrientationControllerSpy()
    let handler = VideoPlayerFullscreenTransitionHandler(orientationController: orientationController)

    handler.playerWillBeginFullscreen()

    #expect(orientationController.fullscreenValues == [true])
  }

  @Test
  func endFullscreenRequestsPortraitRestore() {
    let orientationController = OrientationControllerSpy()
    let handler = VideoPlayerFullscreenTransitionHandler(orientationController: orientationController)

    handler.playerWillEndFullscreen()

    #expect(orientationController.fullscreenValues == [false])
  }
}

@MainActor
private final class OrientationControllerSpy: VideoPlayerOrientationControlling {
  private(set) var fullscreenValues: [Bool] = []

  func setFullscreen(_ isFullscreen: Bool) {
    fullscreenValues.append(isFullscreen)
  }
}
