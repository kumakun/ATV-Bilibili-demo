//
//  FavoriteView.swift
//  BilibiliLive-iOS
//
//  Created by niuniu on 2026/3/5.
//

import SwiftUI

struct FavoriteView: View {
  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 16) {
          // 收藏夹列表
          ForEach(0..<5, id: \.self) { index in
            FavoriteFolder(name: "收藏夹 \(index + 1)", count: Int.random(in: 10...100))
          }
        }
        .padding()
      }
      .navigationTitle("收藏")
    }
  }
}

struct FavoriteFolder: View {
  let name: String
  let count: Int

  var body: some View {
    HStack(spacing: 12) {
      // 文件夹图标
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.pink.opacity(0.2))
        .frame(width: 60, height: 60)
        .overlay {
          Image(systemName: "folder.fill")
            .font(.title2)
            .foregroundStyle(.pink)
        }

      // 信息
      VStack(alignment: .leading, spacing: 4) {
        Text(name)
          .font(.subheadline)
          .fontWeight(.medium)

        Text("\(count) 个内容")
          .font(.caption)
          .foregroundStyle(.secondary)
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
}

#Preview {
  FavoriteView()
}
