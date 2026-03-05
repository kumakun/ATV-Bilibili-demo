//
//  ProfileView.swift
//  BilibiliLive-iOS
//
//  Created by niuniu on 2026/3/5.
//

import SwiftUI

struct ProfileView: View {
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 20) {
          // 用户信息卡片
          UserInfoCard()

          // 数据统计
          UserStatsView()

          // 功能列表
          FunctionListSection()
        }
        .padding()
      }
      .navigationTitle("我的")
    }
  }
}

struct UserInfoCard: View {
  var body: some View {
    HStack(spacing: 16) {
      // 头像
      Circle()
        .fill(
          LinearGradient(
            colors: [.pink, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 70, height: 70)
        .overlay {
          Image(systemName: "person.fill")
            .font(.title)
            .foregroundStyle(.white)
        }

      // 用户信息
      VStack(alignment: .leading, spacing: 6) {
        Text("用户昵称")
          .font(.title3)
          .fontWeight(.semibold)

        Text("这是一段个人签名...")
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }

      Spacer()

      // 二维码
      Button(action: {}) {
        Image(systemName: "qrcode")
          .font(.title3)
          .foregroundStyle(.secondary)
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
  }
}

struct UserStatsView: View {
  var body: some View {
    HStack(spacing: 0) {
      StatItem(title: "关注", value: "123")
      Divider().frame(height: 40)
      StatItem(title: "粉丝", value: "456")
      Divider().frame(height: 40)
      StatItem(title: "获赞", value: "789")
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
  }
}

struct StatItem: View {
  let title: String
  let value: String

  var body: some View {
    VStack(spacing: 4) {
      Text(value)
        .font(.title3)
        .fontWeight(.semibold)
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
  }
}

struct FunctionListSection: View {
  var body: some View {
    VStack(spacing: 0) {
      FunctionItem(icon: "clock.fill", title: "历史记录", color: .blue)
      Divider().padding(.leading, 60)

      FunctionItem(icon: "arrow.down.circle.fill", title: "离线缓存", color: .green)
      Divider().padding(.leading, 60)

      FunctionItem(icon: "star.fill", title: "我的收藏", color: .orange)
      Divider().padding(.leading, 60)

      FunctionItem(icon: "eye.fill", title: "稍后再看", color: .purple)
      Divider().padding(.leading, 60)

      FunctionItem(icon: "gearshape.fill", title: "设置", color: .gray)
    }
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
  }
}

struct FunctionItem: View {
  let icon: String
  let title: String
  let color: Color

  var body: some View {
    Button(action: {}) {
      HStack(spacing: 16) {
        Image(systemName: icon)
          .font(.title3)
          .foregroundStyle(color)
          .frame(width: 28)

        Text(title)
          .foregroundStyle(.primary)

        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding()
    }
  }
}

#Preview {
  ProfileView()
}
