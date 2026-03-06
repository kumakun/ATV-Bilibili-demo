//
//  FollowUpsView.swift
//  BilibiliLive-iOS
//
//  Created by iOS Implementation on 2026/3/5.
//

import SwiftUI

private enum FollowUpsGridLayout {
  static let spacing: CGFloat = 12
  static let horizontalPadding: CGFloat = 16
  static let iPadMinimumCardWidth: CGFloat = 220
  static let iPhoneColumnCount = 2

  static func columnCount(for idiom: UIUserInterfaceIdiom, availableWidth: CGFloat) -> Int {
    let contentWidth = max(availableWidth - (horizontalPadding * 2), 0)

    guard idiom == .pad else {
      return iPhoneColumnCount
    }

    let adaptiveCount = max(
      Int((contentWidth + spacing) / (iPadMinimumCardWidth + spacing)),
      1
    )

    if contentWidth >= minimumWidthForThreeColumns {
      return max(adaptiveCount, 3)
    }

    return adaptiveCount
  }

  static func columns(for idiom: UIUserInterfaceIdiom, availableWidth: CGFloat) -> [GridItem] {
    Array(
      repeating: GridItem(.flexible(), spacing: spacing, alignment: .top),
      count: columnCount(for: idiom, availableWidth: availableWidth)
    )
  }

  static var minimumWidthForThreeColumns: CGFloat {
    (iPadMinimumCardWidth * 3) + (spacing * 2)
  }
}

struct FollowUpsView: View {
  @State private var viewModel = FollowUpsViewModel()

  private func columns(for availableWidth: CGFloat) -> [GridItem] {
    FollowUpsGridLayout.columns(
      for: UIDevice.current.userInterfaceIdiom, availableWidth: availableWidth)
  }

  var body: some View {
    GeometryReader { proxy in
      Group {
        if viewModel.isLoading && viewModel.users.isEmpty {
          ProgressView("加载中...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage, viewModel.users.isEmpty {
          VStack(spacing: 12) {
            Text(error)
              .foregroundStyle(.secondary)
            Button("重试") {
              Task { await viewModel.loadInitial() }
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.users.isEmpty {
          ContentUnavailableView("暂无关注UP", systemImage: "person.2.slash")
        } else {
          ScrollView {
            LazyVGrid(columns: columns(for: proxy.size.width), spacing: FollowUpsGridLayout.spacing)
            {
              ForEach(viewModel.users) { user in
                NavigationLink(value: user) {
                  FollowUpCard(user: user)
                    .onAppear {
                      Task {
                        await viewModel.loadMoreIfNeeded(currentUser: user)
                      }
                    }
                }
                .buttonStyle(.plain)
              }
            }
            .padding(.horizontal, FollowUpsGridLayout.horizontalPadding)
            .padding(.vertical, FollowUpsGridLayout.spacing)

            if viewModel.isLoadingMore {
              ProgressView()
                .padding(.bottom, 16)
            }
          }
          .refreshable {
            await viewModel.refresh()
          }
        }
      }
    }
    .navigationTitle("关注UP")
    .navigationBarTitleDisplayMode(.inline)
    .navigationDestination(for: FollowingUser.self) { user in
      UpSpacePlaceholderView(user: user)
    }
    .task {
      await viewModel.loadInitial()
    }
  }
}

private struct FollowUpCard: View {
  let user: FollowingUser

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 10) {
        AsyncImage(url: user.faceURL) { image in
          image.resizable().scaledToFill()
        } placeholder: {
          Circle().fill(.gray.opacity(0.25))
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())

        Text(user.uname)
          .font(.subheadline)
          .fontWeight(.semibold)
          .lineLimit(1)
          .frame(maxWidth: .infinity, alignment: .leading)

        Spacer(minLength: 0)
      }

      Text(user.sign.isEmpty ? "这个UP很神秘，什么也没有写。" : user.sign)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, minHeight: 108, alignment: .topLeading)
    .padding(12)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

private struct UpSpacePlaceholderView: View {
  let user: FollowingUser

  var body: some View {
    VStack(spacing: 12) {
      AsyncImage(url: user.faceURL) { image in
        image.resizable().scaledToFill()
      } placeholder: {
        Circle().fill(.gray.opacity(0.25))
      }
      .frame(width: 80, height: 80)
      .clipShape(Circle())

      Text(user.uname)
        .font(.title3)
        .fontWeight(.semibold)

      Text("个人空间页面待实现")
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
    .navigationTitle("UP空间")
    .secondaryPageTabBarHidden()
  }
}
