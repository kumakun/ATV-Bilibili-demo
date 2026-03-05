//
//  ProfileView.swift
//  BilibiliLive-iOS
//
//  Created by niuniu on 2026/3/5.
//

import SwiftUI

struct ProfileView: View {
  @State private var viewModel = ProfileViewModel()
  @State private var path = NavigationPath()
  @State private var showLogoutConfirm = false

  var body: some View {
    NavigationStack(path: $path) {
      ScrollView {
        VStack(spacing: 20) {
          // 用户信息卡片
          UserInfoCard(viewModel: viewModel)

          // 数据统计
          UserStatsView(viewModel: viewModel)

          // 功能列表
          FunctionListSection(
            onNavigate: { route in
              path.append(route)
            },
            onLogout: {
              showLogoutConfirm = true
            }
          )
        }
        .padding()
      }
      .navigationTitle("我的")
      .navigationDestination(for: ProfileRoute.self) { route in
        switch route {
        case .followUps:
          FollowUpsView()
        case .followBangumi:
          FollowBangumiView()
        case .watchHistory:
          WatchHistoryView()
        case .watchLater:
          WatchLaterView()
        case .weeklyWatch:
          WeeklyWatchView()
        case .accountSwitcher:
          AccountSwitcherView()
        case .videoDetail(let aid):
          // TODO: Replace with actual video detail view
          Text("视频详情页: \(aid)")
        }
      }
      .task {
        await viewModel.loadProfile()
      }
      .refreshable {
        await viewModel.refreshProfile()
      }
      .onChange(of: viewModel.currentAccount?.profile.mid) { oldValue, newValue in
        // 账号切换时自动刷新
        if oldValue != newValue, newValue != nil {
          Task {
            await viewModel.loadProfile()
          }
        }
      }
    }
    .confirmationDialog("确定要登出吗？", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
      Button("登出", role: .destructive) {
        Task {
          await viewModel.logout()
        }
      }
      Button("取消", role: .cancel) {}
    }
    .alert(
      "登出失败", isPresented: .constant(viewModel.logoutError != nil),
      actions: {
        Button("确定") {
          viewModel.logoutError = nil
        }
      },
      message: {
        Text(viewModel.logoutError ?? "")
      })
  }
}

struct UserInfoCard: View {
  let viewModel: ProfileViewModel
  @State private var showQRCode = false

  var body: some View {
    HStack(spacing: 16) {
      // 头像
      Group {
        if let avatarURL = viewModel.avatarURL {
          AsyncImage(url: avatarURL) { image in
            image
              .resizable()
              .scaledToFill()
          } placeholder: {
            Circle()
              .fill(Color.gray.opacity(0.3))
              .overlay {
                ProgressView()
              }
          }
        } else {
          Circle()
            .fill(
              LinearGradient(
                colors: [.pink, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .overlay {
              Image(systemName: "person.fill")
                .font(.title)
                .foregroundStyle(.white)
            }
        }
      }
      .frame(width: 70, height: 70)
      .clipShape(Circle())

      // 用户信息
      VStack(alignment: .leading, spacing: 6) {
        Text(viewModel.displayName)
          .font(.title3)
          .fontWeight(.semibold)

        Text(viewModel.signature)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }

      Spacer()

      // 二维码
      Button(action: {
        showQRCode = true
      }) {
        Image(systemName: "qrcode")
          .font(.title3)
          .foregroundStyle(.secondary)
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    .sheet(isPresented: $showQRCode) {
      Text("二维码功能")
        .presentationDetents([.medium])
    }
  }
}

struct UserStatsView: View {
  let viewModel: ProfileViewModel

  var body: some View {
    HStack(spacing: 0) {
      StatItem(title: "关注", value: viewModel.followingCount)
      Divider().frame(height: 40)
      StatItem(title: "粉丝", value: viewModel.followerCount)
      Divider().frame(height: 40)
      StatItem(title: "获赞", value: viewModel.likesCount)
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
  let onNavigate: (ProfileRoute) -> Void
  let onLogout: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      FunctionItem(icon: "person.2.fill", title: "关注UP", color: .blue) {
        onNavigate(.followUps)
      }
      Divider().padding(.leading, 60)

      FunctionItem(icon: "tv.fill", title: "追番追剧", color: .green) {
        onNavigate(.followBangumi)
      }
      Divider().padding(.leading, 60)

      FunctionItem(icon: "clock.fill", title: "历史记录", color: .orange) {
        onNavigate(.watchHistory)
      }
      Divider().padding(.leading, 60)

      FunctionItem(icon: "eye.fill", title: "稍后再看", color: .purple) {
        onNavigate(.watchLater)
      }
      Divider().padding(.leading, 60)

      FunctionItem(icon: "flame.fill", title: "每周必看", color: .red) {
        onNavigate(.weeklyWatch)
      }
      Divider().padding(.leading, 60)

      FunctionItem(icon: "person.crop.circle.badge.checkmark", title: "账号切换", color: .gray) {
        onNavigate(.accountSwitcher)
      }
      Divider().padding(.leading, 60)

      FunctionItem(icon: "arrow.right.to.line.circle.fill", title: "登出", color: .red) {
        onLogout()
      }
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
  let action: () -> Void

  var body: some View {
    Button(action: action) {
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
