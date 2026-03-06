//
//  FollowView.swift
//  BilibiliLive-iOS
//
//  Created by niuniu on 2026/3/5.
//

import SwiftUI

struct FollowView: View {
  @State private var viewModel = FollowViewModel()

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // 内容区域
        Group {
          if viewModel.isLoading && viewModel.videoFeeds.isEmpty {
            ProgressView("加载中...")
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else if let error = viewModel.errorMessage, viewModel.videoFeeds.isEmpty {
            VStack(spacing: 12) {
              Text(error)
                .foregroundStyle(.secondary)
              Button("重试") {
                Task { await viewModel.loadInitial() }
              }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else if viewModel.videoFeeds.isEmpty {
            ContentUnavailableView("暂无关注动态", systemImage: "heart.slash")
          } else {
            ScrollView {
              LazyVStack(spacing: 16) {
                ForEach(viewModel.videoFeeds) { feed in
                  NavigationLink(value: feed) {
                    DynamicFeedCard(feed: feed)
                      .onAppear {
                        Task {
                          await viewModel.loadMoreIfNeeded(currentFeed: feed)
                        }
                      }
                  }
                  .buttonStyle(.plain)
                }

                if viewModel.isLoadingMore {
                  ProgressView()
                    .padding(.bottom, 16)
                }
              }
              .padding()
            }
            .refreshable {
              await viewModel.refresh()
            }
          }
        }
      }
      .navigationDestination(for: DynamicFeedData.self) { feed in
        VideoDetailPlaceholderView(feed: feed)
      }
      .task {
        await viewModel.loadInitial()
      }
    }
  }
}

// MARK: - DynamicFeedCard

private struct DynamicFeedCard: View {
  let feed: DynamicFeedData

  var body: some View {
    VStack(spacing: 0) {
      // UP主信息
      HStack(spacing: 12) {
        AsyncImage(url: feed.avatar) { image in
          image
            .resizable()
            .scaledToFill()
        } placeholder: {
          Circle()
            .fill(Color(.systemGray5))
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())

        VStack(alignment: .leading, spacing: 2) {
          Text(feed.ownerName)
            .font(.subheadline)
            .fontWeight(.medium)
          Text(feed.pubTime)
            .font(.caption2)
            .foregroundStyle(.secondary)
        }

        Spacer()
      }
      .padding(.horizontal)
      .padding(.vertical, 8)

      // 视频封面
      AsyncImage(url: feed.pic) { image in
        image
          .resizable()
          .scaledToFill()
      } placeholder: {
        Rectangle()
          .fill(Color(.systemGray5))
      }
      .aspectRatio(16 / 9, contentMode: .fit)
      .overlay(alignment: .bottomTrailing) {
        if let duration = feed.duration {
          Text(duration)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.black.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(4)
            .padding(8)
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 8))
      .padding(.horizontal)

      // 视频信息
      VStack(alignment: .leading, spacing: 6) {
        Text(feed.title)
          .font(.subheadline)
          .fontWeight(.medium)
          .lineLimit(2)

        HStack(spacing: 16) {
          Label(feed.playCountString, systemImage: "play.fill")
          Label(feed.danmakuCountString, systemImage: "text.bubble")
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

// MARK: - VideoDetailPlaceholderView

private struct VideoDetailPlaceholderView: View {
  let feed: DynamicFeedData

  var body: some View {
    VStack(spacing: 20) {
      Text("视频详情页")
        .font(.largeTitle)
        .fontWeight(.bold)

      VStack(alignment: .leading, spacing: 8) {
        Text("标题: \(feed.title)")
        Text("AID: \(feed.aid)")
        Text("UP主: \(feed.ownerName)")
        if let epid = feed.epid {
          Text("EPID: \(epid)")
        }
      }
      .font(.body)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
      .background(Color(.systemGray6))
      .cornerRadius(12)
      .padding()

      Text("详情页面待实现")
        .foregroundStyle(.secondary)
    }
    .padding()
    .navigationTitle("视频详情")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  FollowView()
}
