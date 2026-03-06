//
//  FollowView.swift
//  BilibiliLive-iOS
//
//  Created by niuniu on 2026/3/5.
//

import SwiftUI
import UIKit

struct FollowView: View {
  @State private var viewModel = FollowViewModel()
  private let gridSpacing: CGFloat = 12
  private let horizontalPadding: CGFloat = 16

  var body: some View {
    NavigationStack {
      GeometryReader { geometry in
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
                VStack(spacing: 16) {
                  LazyVGrid(columns: gridColumns(for: geometry.size.width), spacing: gridSpacing) {
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
                  }

                  if viewModel.isLoadingMore {
                    ProgressView()
                      .frame(maxWidth: .infinity)
                      .padding(.bottom, 4)
                  }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 12)
              }
              .refreshable {
                await viewModel.refresh()
              }
            }
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      }
      .navigationDestination(for: DynamicFeedData.self) { feed in
        VideoDetailView(aid: feed.aid)
      }
      .task {
        await viewModel.loadInitial()
      }
    }
  }

  private func gridColumns(for width: CGFloat) -> [GridItem] {
    let usableWidth = max(width - (horizontalPadding * 2), 0)
    let isPhone = UIDevice.current.userInterfaceIdiom == .phone

    let columnCount: Int
    if isPhone {
      columnCount = 2
    } else {
      let minimumCardWidth: CGFloat = 240
      let adaptiveCount = Int((usableWidth + gridSpacing) / (minimumCardWidth + gridSpacing))
      columnCount = max(2, adaptiveCount)
    }

    return Array(
      repeating: GridItem(.flexible(), spacing: gridSpacing, alignment: .top), count: columnCount)
  }
}

// MARK: - DynamicFeedCard

private struct DynamicFeedCard: View {
  let feed: DynamicFeedData

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
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
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.black.opacity(0.75))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .padding(8)
        }
      }

      VStack(alignment: .leading, spacing: 10) {
        Text(feed.title)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
          .lineLimit(2)
          .multilineTextAlignment(.leading)

        HStack(alignment: .center, spacing: 8) {
          AsyncImage(url: feed.avatar) { image in
            image
              .resizable()
              .scaledToFill()
          } placeholder: {
            Circle()
              .fill(Color(.systemGray5))
          }
          .frame(width: 28, height: 28)
          .clipShape(Circle())

          VStack(alignment: .leading, spacing: 2) {
            Text(feed.ownerName)
              .font(.caption)
              .fontWeight(.medium)
              .lineLimit(1)
            Text(feed.pubTime)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }

          Spacer(minLength: 0)
        }

        HStack(spacing: 10) {
          Label(feed.playCountString, systemImage: "play.fill")
            .lineLimit(1)
          Label(feed.danmakuCountString, systemImage: "text.bubble")
            .lineLimit(1)
          Spacer(minLength: 0)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
      }
      .padding(12)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(Color.black.opacity(0.04), lineWidth: 1)
    }
    .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
  }
}

#Preview {
  FollowView()
}
