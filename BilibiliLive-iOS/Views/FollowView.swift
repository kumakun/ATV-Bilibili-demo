//
//  FollowView.swift
//  BilibiliLive-iOS
//
//  Created by niuniu on 2026/3/5.
//

import SwiftUI

struct FollowView: View {
  @State private var selectedFilter = 0

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // 筛选器
        Picker("筛选", selection: $selectedFilter) {
          Text("全部").tag(0)
          Text("视频").tag(1)
          Text("直播").tag(2)
        }
        .pickerStyle(.segmented)
        .padding()

        // 内容列表
        ScrollView {
          LazyVStack(spacing: 16) {
            ForEach(0..<15, id: \.self) { index in
              FollowVideoCard(index: index)
            }
          }
          .padding()
        }
      }
      .navigationTitle("关注")
    }
  }
}

struct FollowVideoCard: View {
  let index: Int

  var body: some View {
    VStack(spacing: 0) {
      // UP主信息
      HStack(spacing: 12) {
        Circle()
          .fill(Color.pink.opacity(0.3))
          .frame(width: 36, height: 36)
          .overlay {
            Image(systemName: "person.fill")
              .font(.subheadline)
              .foregroundStyle(.pink)
          }

        VStack(alignment: .leading, spacing: 2) {
          Text("UP主名称 \(index + 1)")
            .font(.subheadline)
            .fontWeight(.medium)
          Text("2小时前")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Button(action: {}) {
          Image(systemName: "ellipsis")
            .foregroundStyle(.secondary)
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 8)

      // 视频封面
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(.systemGray5))
        .aspectRatio(16 / 9, contentMode: .fit)
        .overlay {
          VStack(spacing: 8) {
            Image(systemName: "play.circle.fill")
              .font(.system(size: 50))
              .foregroundStyle(.white.opacity(0.9))

            Text("12:34")
              .font(.caption)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(.black.opacity(0.6))
              .foregroundColor(.white)
              .cornerRadius(4)
          }
        }
        .padding(.horizontal)

      // 视频信息
      VStack(alignment: .leading, spacing: 6) {
        Text("视频标题：这是一个比较长的视频标题用来展示多行文本的效果...")
          .font(.subheadline)
          .fontWeight(.medium)
          .lineLimit(2)

        HStack(spacing: 16) {
          Label("10.5万", systemImage: "play.fill")
          Label("2345", systemImage: "text.bubble")
          Label("3天前", systemImage: "clock")
          Spacer()
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
      .padding()
    }
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
  }
}

#Preview {
  FollowView()
}
