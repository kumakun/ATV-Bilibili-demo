//
//  VideoPlayerOrientationPolicyTests.swift
//  BilibiliLive-iOSTests
//
//  Created by Codex on 2026/3/23.
//

import Testing
import UIKit
@testable import BilibiliLive_iOS

struct VideoPlayerOrientationPolicyTests {

  @Test
  func enteringFullscreenUsesLandscapeOrientation() {
    let configuration = VideoPlayerOrientationPolicy.configuration(forFullscreen: true, idiom: .phone)

    #expect(configuration.supportedOrientations == .landscape)
    #expect(configuration.requestedOrientations == .landscapeRight)
    #expect(configuration.preferredOrientation == .landscapeRight)
  }

  @Test
  func leavingFullscreenRestoresPortraitOrientation() {
    let configuration = VideoPlayerOrientationPolicy.configuration(forFullscreen: false, idiom: .phone)

    #expect(configuration.supportedOrientations == .allButUpsideDown)
    #expect(configuration.requestedOrientations == .portrait)
    #expect(configuration.preferredOrientation == .portrait)
  }
}
