//
//  HomeView.swift
//  BilibiliLive-iOS
//
//  Created by niuniu on 2026/3/5.
//

import SwiftUI

struct HomeView: View {
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          // 横幅区域
          BannerPlaceholder()

          // 推荐视频列表占位
          LazyVStack(spacing: 16) {
            ForEach(0..<10, id: \.self) { index in
              VideoCardPlaceholder(title: "视频标题 \(index + 1)")
            }
          }
          .padding(.horizontal)
        }
      }
      .navigationTitle("首页")
    }
  }
}

// 横幅占位
struct BannerPlaceholder: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 12)
      .fill(
        LinearGradient(
          colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
      .frame(height: 180)
      .padding(.horizontal)
      .overlay {
        Text("横幅区域")
          .font(.title3)
          .foregroundStyle(.white)
      }
  }
}

// 视频卡片占位
struct VideoCardPlaceholder: View {
  let title: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // 封面
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(.systemGray5))
        .aspectRatio(16 / 9, contentMode: .fit)
        .overlay {
          Image(systemName: "play.circle.fill")
            .font(.system(size: 40))
            .foregroundStyle(.white.opacity(0.8))
        }

      // 标题和信息
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.subheadline)
          .fontWeight(.medium)
          .lineLimit(2)

        HStack {
          Label("UP主", systemImage: "person.circle")
          Spacer()
          Label("10万", systemImage: "play.fill")
          Label("1234", systemImage: "text.bubble")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
    }
    .background(Color(.systemBackground))
  }
}

#Preview {
  HomeView()
}
