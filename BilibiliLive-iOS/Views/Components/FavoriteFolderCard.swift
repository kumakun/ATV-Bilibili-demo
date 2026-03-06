//
//  FavoriteFolderCard.swift
//  BilibiliLive-iOS
//
//  Created on 2026/3/6.
//

import SwiftUI

struct FavoriteFolderCard: View {
  let folder: FavListDataIOS

  var body: some View {
    HStack(spacing: 12) {
      // 文件夹图标
      RoundedRectangle(cornerRadius: 8)
        .fill(iconColor.opacity(0.2))
        .frame(width: 60, height: 60)
        .overlay {
          Image(systemName: iconName)
            .font(.title2)
            .foregroundStyle(iconColor)
        }

      // 信息
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Text(folder.title)
            .font(.subheadline)
            .fontWeight(.medium)
            .lineLimit(1)

          // 订阅标签
          if !folder.isCreatedBySelf {
            Text("订阅")
              .font(.caption2)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color.orange.opacity(0.2))
              .foregroundStyle(.orange)
              .cornerRadius(4)
          }
        }

        if let count = folder.mediaCount {
          Text("\(count) 个内容")
            .font(.caption)
            .foregroundStyle(.secondary)
        } else {
          Text("收藏夹")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      Image(systemName: "chevron.right")
        .foregroundStyle(.secondary)
        .font(.caption)
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
  }

  // MARK: - Computed Properties

  private var iconName: String {
    folder.isCreatedBySelf ? "folder.fill" : "folder.badge.person.crop"
  }

  private var iconColor: Color {
    folder.isCreatedBySelf ? .pink : .orange
  }
}

#Preview {
  VStack(spacing: 16) {
    FavoriteFolderCard(
      folder: FavListDataIOS(id: 1, title: "我的收藏", mediaCount: 42, isCreatedBySelf: true))
    FavoriteFolderCard(
      folder: FavListDataIOS(
        id: 2, title: "订阅的收藏夹", mediaCount: 18, isCreatedBySelf: false, mid: 12345))
  }
  .padding()
}
