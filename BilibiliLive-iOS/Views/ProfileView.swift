//
//  ProfileView.swift
//  BilibiliLive-iOS
//
//  Created by niuniu on 2026/3/5.
//

import SwiftUI

struct ProfileView: View {
  @State private var viewModel = ProfileViewModel()
  @State private var iPhonePath = NavigationPath()
  @State private var iPadDetailPath = NavigationPath()
  @State private var selectedRoute: ProfileRoute?
  @State private var showAccountSwitcher = false
  @State private var showLogoutConfirm = false

  // 设备检测：iPad 使用 SplitView，iPhone 使用 NavigationStack
  private var isPad: Bool {
    UIDevice.current.userInterfaceIdiom == .pad
  }

  private let sidebarRoutes: [ProfileRoute] = [
    .followUps,
    .followBangumi,
    .watchHistory,
    .watchLater,
    .weeklyWatch,
  ]

  var body: some View {
    Group {
      if isPad {
        iPadLayout
      } else {
        iPhoneLayout
      }
    }
    .task {
      await viewModel.loadProfile()
    }
    .onChange(of: viewModel.currentAccount?.profile.mid) { oldValue, newValue in
      // 账号切换后刷新并重置 iPad 选中状态
      if oldValue != newValue {
        selectedRoute = nil
        iPadDetailPath = NavigationPath()

        if newValue != nil {
          Task {
            await viewModel.loadProfile()
          }
        }
      }
    }
    .sheet(isPresented: $showAccountSwitcher) {
      AccountSwitcherView()
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

  private var iPadLayout: some View {
    NavigationSplitView {
      VStack(spacing: 12) {
        UserInfoCard(viewModel: viewModel)
          .padding(.horizontal)
          .padding(.top, 12)

        List(selection: $selectedRoute) {
          ForEach(sidebarRoutes, id: \.self) { route in
            NavigationLink(value: route) {
              ProfileFunctionRow(item: item(for: route), showChevron: false)
            }
            .tag(route)
            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
          }

          Section {
            Button {
              showAccountSwitcher = true
              selectedRoute = nil
            } label: {
              ProfileFunctionRow(
                item: ProfileMenuItem(
                  icon: "person.crop.circle.badge.checkmark",
                  title: "账号切换",
                  color: .gray
                ),
                showChevron: false
              )
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))

            Button(role: .destructive) {
              showLogoutConfirm = true
              selectedRoute = nil
            } label: {
              ProfileFunctionRow(
                item: ProfileMenuItem(
                  icon: "arrow.right.to.line.circle.fill",
                  title: "登出",
                  color: .red
                ),
                showChevron: false
              )
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
          }
        }
        .listStyle(.sidebar)
        .refreshable {
          await viewModel.refreshProfile()
        }
      }
      .background(Color(.systemGroupedBackground))
    } detail: {
      NavigationStack(path: $iPadDetailPath) {
        Group {
          if let route = selectedRoute {
            destinationView(for: route)
          } else {
            ContentUnavailableView(
              "请选择左侧功能",
              systemImage: "sidebar.left"
            )
          }
        }
        .navigationDestination(for: ProfileRoute.self) { route in
          destinationView(for: route)
        }
      }
    }
    .navigationSplitViewStyle(.balanced)
    .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 360)
  }

  private var iPhoneLayout: some View {
    NavigationStack(path: $iPhonePath) {
      ScrollView {
        VStack(spacing: 20) {
          UserInfoCard(viewModel: viewModel)

          FunctionListSection(
            onNavigate: { route in
              iPhonePath.append(route)
            },
            onLogout: {
              showLogoutConfirm = true
            }
          )
        }
        .padding()
      }
      .navigationDestination(for: ProfileRoute.self) { route in
        destinationView(for: route)
      }
      .refreshable {
        await viewModel.refreshProfile()
      }
    }
  }

  @ViewBuilder
  private func destinationView(for route: ProfileRoute) -> some View {
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

  private func item(for route: ProfileRoute) -> ProfileMenuItem {
    switch route {
    case .followUps:
      return ProfileMenuItem(icon: "person.2.fill", title: "关注UP", color: .blue)
    case .followBangumi:
      return ProfileMenuItem(icon: "tv.fill", title: "追番追剧", color: .green)
    case .watchHistory:
      return ProfileMenuItem(icon: "clock.fill", title: "历史记录", color: .orange)
    case .watchLater:
      return ProfileMenuItem(icon: "eye.fill", title: "稍后再看", color: .purple)
    case .weeklyWatch:
      return ProfileMenuItem(icon: "flame.fill", title: "每周必看", color: .red)
    case .accountSwitcher:
      return ProfileMenuItem(
        icon: "person.crop.circle.badge.checkmark", title: "账号切换", color: .gray)
    case .videoDetail:
      return ProfileMenuItem(icon: "play.circle.fill", title: "视频详情", color: .secondary)
    }
  }
}

struct ProfileMenuItem {
  let icon: String
  let title: String
  let color: Color
}

private struct ProfileFunctionRow: View {
  let item: ProfileMenuItem
  var showChevron = true

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: item.icon)
        .font(.title3)
        .foregroundStyle(item.color)
        .frame(width: 28)

      Text(item.title)
        .foregroundStyle(.primary)

      Spacer()

      if showChevron {
        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 8)
    .padding(.horizontal, 4)
  }
}

struct UserInfoCard: View {
  let viewModel: ProfileViewModel
  @State private var showQRCode = false

  var body: some View {
    HStack(spacing: 16) {
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

struct FunctionListSection: View {
  let onNavigate: (ProfileRoute) -> Void
  let onLogout: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      FunctionItem(item: ProfileMenuItem(icon: "person.2.fill", title: "关注UP", color: .blue)) {
        onNavigate(.followUps)
      }
      Divider().padding(.leading, 60)

      FunctionItem(item: ProfileMenuItem(icon: "tv.fill", title: "追番追剧", color: .green)) {
        onNavigate(.followBangumi)
      }
      Divider().padding(.leading, 60)

      FunctionItem(item: ProfileMenuItem(icon: "clock.fill", title: "历史记录", color: .orange)) {
        onNavigate(.watchHistory)
      }
      Divider().padding(.leading, 60)

      FunctionItem(item: ProfileMenuItem(icon: "eye.fill", title: "稍后再看", color: .purple)) {
        onNavigate(.watchLater)
      }
      Divider().padding(.leading, 60)

      FunctionItem(item: ProfileMenuItem(icon: "flame.fill", title: "每周必看", color: .red)) {
        onNavigate(.weeklyWatch)
      }
      Divider().padding(.leading, 60)

      FunctionItem(
        item: ProfileMenuItem(
          icon: "person.crop.circle.badge.checkmark", title: "账号切换", color: .gray)
      ) {
        onNavigate(.accountSwitcher)
      }
      Divider().padding(.leading, 60)

      FunctionItem(
        item: ProfileMenuItem(icon: "arrow.right.to.line.circle.fill", title: "登出", color: .red)
      ) {
        onLogout()
      }
    }
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
  }
}

struct FunctionItem: View {
  let item: ProfileMenuItem
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ProfileFunctionRow(item: item)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
  }
}

#Preview {
  ProfileView()
}
