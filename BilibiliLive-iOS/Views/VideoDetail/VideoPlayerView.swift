//
//  VideoPlayerView.swift
//  BilibiliLive-iOS
//
//  Created by GitHub Copilot on 2026/3/6.
//

import AVKit
import SwiftUI

@MainActor
final class VideoPlayerFullscreenTransitionHandler {
  private let orientationController: VideoPlayerOrientationControlling

  init(orientationController: VideoPlayerOrientationControlling) {
    self.orientationController = orientationController
  }

  func playerWillBeginFullscreen() {
    orientationController.setFullscreen(true)
  }

  func playerWillEndFullscreen() {
    orientationController.setFullscreen(false)
  }
}

struct VideoPlayerView: View {
  let player: AVPlayer?
  let availablePlaybackQualities: [VideoPlaybackQualityOption]
  let selectedPlaybackQuality: VideoPlaybackQualityTier?
  let onPlaybackQualitySelected: (VideoPlaybackQualityTier) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if let player = player {
        PlayerViewController(player: player, showsPlaybackControls: true)
          .aspectRatio(16 / 9, contentMode: .fit)
          .background(Color.black)
      } else {
        Rectangle()
          .fill(Color.black)
          .aspectRatio(16 / 9, contentMode: .fit)
          .overlay(
            ProgressView()
              .tint(.white)
          )
      }

      if availablePlaybackQualities.count > 1 {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 10) {
            ForEach(availablePlaybackQualities) { quality in
              Button {
                onPlaybackQualitySelected(quality.tier)
              } label: {
                Text(quality.tier.title)
                  .font(.subheadline.weight(.semibold))
                  .foregroundStyle(
                    selectedPlaybackQuality == quality.tier ? Color.white : Color.primary
                  )
                  .padding(.horizontal, 14)
                  .padding(.vertical, 8)
                  .background(
                    Capsule()
                      .fill(selectedPlaybackQuality == quality.tier ? Color.accentColor : Color(.secondarySystemFill))
                  )
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
    }
  }
}

private struct PlayerViewController: UIViewControllerRepresentable {
  let player: AVPlayer
  let showsPlaybackControls: Bool

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let controller = AVPlayerViewController()
    controller.player = player
    controller.showsPlaybackControls = showsPlaybackControls
    controller.videoGravity = .resizeAspect
    controller.allowsPictureInPicturePlayback = true
    controller.canStartPictureInPictureAutomaticallyFromInline = true
    controller.delegate = context.coordinator
    return controller
  }

  func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
    if uiViewController.player !== player {
      uiViewController.player = player
    }

    uiViewController.showsPlaybackControls = showsPlaybackControls
    uiViewController.delegate = context.coordinator
  }

  @MainActor
  final class Coordinator: NSObject, AVPlayerViewControllerDelegate {
    private let transitionHandler = VideoPlayerFullscreenTransitionHandler(
      orientationController: VideoPlayerOrientationController.shared
    )

    func playerViewController(
      _ playerViewController: AVPlayerViewController,
      willBeginFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator
    ) {
      transitionHandler.playerWillBeginFullscreen()
    }

    func playerViewController(
      _ playerViewController: AVPlayerViewController,
      willEndFullScreenPresentationWithAnimationCoordinator coordinator: any UIViewControllerTransitionCoordinator
    ) {
      transitionHandler.playerWillEndFullscreen()
    }
  }
}

#Preview {
  VideoPlayerView(
    player: nil,
    availablePlaybackQualities: [
      VideoPlaybackQualityOption(tier: .high, qualityID: 120),
      VideoPlaybackQualityOption(tier: .medium, qualityID: 64),
      VideoPlaybackQualityOption(tier: .low, qualityID: 32),
    ],
    selectedPlaybackQuality: .high,
    onPlaybackQualitySelected: { _ in }
  )
}
