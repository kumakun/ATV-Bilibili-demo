//
//  DynamicView.swift
//  BilibiliLive-iOS
//
//  Created by niuniu on 2026/3/5.
//

import SwiftUI

struct DynamicView: View {
  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(spacing: 16) {
          ForEach(0..<10, id: \.self) { index in
            DynamicCardPlaceholder(index: index)
          }
        }
        .padding()
      }
      .navigationTitle("动态")
    }
  }
}

struct DynamicCardPlaceholder: View {
  let index: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // 用户信息
      HStack(spacing: 12) {
        Circle()
          .fill(Color.pink.opacity(0.3))
          .frame(width: 40, height: 40)
          .overlay {
            Image(systemName: "person.fill")
              .foregroundStyle(.pink)
          }

        VStack(alignment: .leading, spacing: 2) {
          Text("用户名 \(index + 1)")
            .font(.subheadline)
            .fontWeight(.medium)
          Text("刚刚")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Button(action: {}) {
          Image(systemName: "ellipsis")
            .foregroundStyle(.secondary)
        }
      }

      // 动态内容
      Text("这是一条动态内容的占位文字，用于展示动态的基本布局...")
        .font(.body)

      // 图片区域（如果有）
      if index % 3 == 0 {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color(.systemGray5))
          .aspectRatio(1.5, contentMode: .fit)
      }

      // 互动按钮
      HStack(spacing: 24) {
        InteractionButton(icon: "hand.thumbsup", count: "123")
        InteractionButton(icon: "bubble.right", count: "45")
        InteractionButton(icon: "arrowshape.turn.up.right", count: "6")
        Spacer()
      }
      .font(.subheadline)
      .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
  }
}

struct InteractionButton: View {
  let icon: String
  let count: String

  var body: some View {
    Button(action: {}) {
      HStack(spacing: 4) {
        Image(systemName: icon)
        Text(count)
      }
    }
  }
}

#Preview {
  DynamicView()
}
