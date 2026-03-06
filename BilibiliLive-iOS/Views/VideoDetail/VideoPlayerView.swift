//
//  VideoPlayerView.swift
//  BilibiliLive-iOS
//
//  Created by GitHub Copilot on 2026/3/6.
//

import AVKit
import SwiftUI

struct VideoPlayerView: View {
  let player: AVPlayer?

  var body: some View {
    if let player = player {
      VideoPlayer(player: player)
        .aspectRatio(16 / 9, contentMode: .fit)
        .background(Color.black)
    } else {
      // 占位符
      Rectangle()
        .fill(Color.black)
        .aspectRatio(16 / 9, contentMode: .fit)
        .overlay(
          ProgressView()
            .tint(.white)
        )
    }
  }
}

#Preview {
  VideoPlayerView(player: nil)
}
