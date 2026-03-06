//
//  VideoStatsView.swift
//  BilibiliLive-iOS
//
//  Created by GitHub Copilot on 2026/3/6.
//

import SwiftUI

struct VideoStatsView: View {
  let stat: VideoDetail.VideoInfo.VideoStat

  var body: some View {
    HStack(spacing: 20) {
      StatItem(icon: "play.fill", value: stat.playCountString)
      StatItem(icon: "text.bubble.fill", value: stat.danmakuCountString)
      StatItem(icon: "heart.fill", value: stat.likeCountString)
      StatItem(icon: "bitcoinsign.circle.fill", value: stat.coinCountString)
      StatItem(icon: "star.fill", value: stat.favoriteCountString)
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding(.horizontal)
  }
}

private struct StatItem: View {
  let icon: String
  let value: String

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: icon)
        .font(.caption2)
      Text(value)
    }
  }
}

#Preview {
  VideoStatsView(
    stat: VideoDetail.VideoInfo.VideoStat(
      favorite: 12345,
      coin: 6789,
      like: 98765,
      share: 432,
      danmaku: 5432,
      view: 123456
    )
  )
}
