//
//  VideoPlayerOrientationController.swift
//  BilibiliLive-iOS
//
//  Created by Codex on 2026/3/23.
//

import UIKit

@MainActor
protocol VideoPlayerOrientationControlling: AnyObject {
  func setFullscreen(_ isFullscreen: Bool)
}

struct VideoPlayerOrientationPolicy {
  struct Configuration: Equatable {
    let supportedOrientations: UIInterfaceOrientationMask
    let requestedOrientations: UIInterfaceOrientationMask
    let preferredOrientation: UIInterfaceOrientation
  }

  static func configuration(
    forFullscreen isFullscreen: Bool,
    idiom: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
  ) -> Configuration {
    if isFullscreen {
      return Configuration(
        supportedOrientations: .landscape,
        requestedOrientations: .landscapeRight,
        preferredOrientation: .landscapeRight
      )
    }

    let supportedOrientations: UIInterfaceOrientationMask = idiom == .pad ? .all : .allButUpsideDown
    let requestedOrientations: UIInterfaceOrientationMask = idiom == .pad ? supportedOrientations : .portrait

    return Configuration(
      supportedOrientations: supportedOrientations,
      requestedOrientations: requestedOrientations,
      preferredOrientation: .portrait
    )
  }
}

@MainActor
final class VideoPlayerOrientationController {
  static let shared = VideoPlayerOrientationController()

  private(set) var supportedOrientations: UIInterfaceOrientationMask = .allButUpsideDown

  private init() {}

  func setFullscreen(_ isFullscreen: Bool) {
    let configuration = VideoPlayerOrientationPolicy.configuration(forFullscreen: isFullscreen)
    supportedOrientations = configuration.supportedOrientations
    apply(configuration)
  }

  private func apply(_ configuration: VideoPlayerOrientationPolicy.Configuration) {
    guard let windowScene = activeWindowScene else { return }

    windowScene.windows.forEach { window in
      window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }

    let preferences = UIWindowScene.GeometryPreferences.iOS(
      interfaceOrientations: configuration.requestedOrientations
    )

    windowScene.requestGeometryUpdate(preferences) { error in
      print("VideoPlayerOrientationController requestGeometryUpdate failed: \(error)")
    }

    windowScene.windows.forEach { window in
      window.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
  }

  private var activeWindowScene: UIWindowScene? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first(where: { $0.activationState == .foregroundActive })
    ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
  }
}

@MainActor
extension VideoPlayerOrientationController: VideoPlayerOrientationControlling {}

final class BilibiliLiveIOSAppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    VideoPlayerOrientationController.shared.supportedOrientations
  }
}
