//
//  FollowUpsView.swift
//  BilibiliLive-iOS
//
//  Created by iOS Implementation on 2026/3/5.
//

import SwiftUI

struct FollowUpsView: View {
  @State private var viewModel = FollowUpsViewModel()

  private var columns: [GridItem] {
    [GridItem(.adaptive(minimum: 150), spacing: 12)]
  }

  var body: some View {
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
          LazyVGrid(columns: columns, spacing: 12) {
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
          .padding()

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

        Spacer(minLength: 0)
      }

      Text(user.sign.isEmpty ? "这个UP很神秘，什么也没有写。" : user.sign)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }
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
  }
}
