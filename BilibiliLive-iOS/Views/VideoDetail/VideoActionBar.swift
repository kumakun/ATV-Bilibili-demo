//
//  VideoActionBar.swift
//  BilibiliLive-iOS
//
//  Created by GitHub Copilot on 2026/3/6.
//

import SwiftUI

struct VideoActionBar: View {
  let isLiked: Bool
  let coinCount: Int
  let isFavorited: Bool

  let onLikeTap: () -> Void
  let onCoinTap: () -> Void
  let onFavoriteTap: () -> Void
  let onShareTap: () -> Void

  var body: some View {
    HStack(spacing: 0) {
      ActionButton(
        icon: isLiked ? "heart.fill" : "heart",
        title: "点赞",
        isActive: isLiked,
        action: onLikeTap
      )

      Divider()
        .frame(height: 30)

      ActionButton(
        icon: coinCount > 0 ? "bitcoinsign.circle.fill" : "bitcoinsign.circle",
        title: "投币",
        isActive: coinCount > 0,
        action: onCoinTap
      )

      Divider()
        .frame(height: 30)

      ActionButton(
        icon: isFavorited ? "star.fill" : "star",
        title: "收藏",
        isActive: isFavorited,
        action: onFavoriteTap
      )

      Divider()
        .frame(height: 30)

      ActionButton(
        icon: "square.and.arrow.up",
        title: "分享",
        isActive: false,
        action: onShareTap
      )
    }
    .frame(height: 50)
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    .padding(.horizontal)
  }
}

private struct ActionButton: View {
  let icon: String
  let title: String
  let isActive: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 20))
        Text(title)
          .font(.caption2)
      }
      .foregroundColor(isActive ? .pink : .primary)
      .frame(maxWidth: .infinity)
    }
  }
}

#Preview {
  VStack {
    VideoActionBar(
      isLiked: false,
      coinCount: 0,
      isFavorited: false,
      onLikeTap: {},
      onCoinTap: {},
      onFavoriteTap: {},
      onShareTap: {}
    )

    VideoActionBar(
      isLiked: true,
      coinCount: 2,
      isFavorited: true,
      onLikeTap: {},
      onCoinTap: {},
      onFavoriteTap: {},
      onShareTap: {}
    )
  }
  .padding()
}
