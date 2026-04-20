//
//  FavoriteFolderView.swift
//  BilibiliLive-iOS
//
//  Created on 2026/3/6.
//

import SwiftUI
import UIKit

struct FavoriteFolderView: View {
  let folder: FavListDataIOS
  @State private var viewModel: FavoriteFolderViewModel
  private let gridSpacing: CGFloat = 12
  private let horizontalPadding: CGFloat = 16

  init(folder: FavListDataIOS) {
    self.folder = folder
    _viewModel = State(initialValue: FavoriteFolderViewModel(folder: folder))
  }

  var body: some View {
    Group {
      if viewModel.isLoading && viewModel.videos.isEmpty {
        // 首次加载状态
        ProgressView("加载中...")
      } else if let error = viewModel.errorMessage, viewModel.videos.isEmpty {
        // 错误状态（仅当列表为空时显示）
        ContentUnavailableView(
          "加载失败",
          systemImage: "exclamationmark.triangle",
          description: Text(error)
        )
        .overlay(alignment: .bottom) {
          Button("重试") {
            Task {
              await viewModel.loadVideos()
            }
          }
          .buttonStyle(.borderedProminent)
          .padding()
        }
      } else if viewModel.videos.isEmpty {
        // 空状态
        ContentUnavailableView(
          "收藏夹为空",
          systemImage: "tray",
          description: Text("这个收藏夹还没有内容")
        )
      } else {
        // 视频列表
        GeometryReader { geometry in
          ScrollView {
            LazyVGrid(
              columns: gridColumns(for: geometry.size.width),
              spacing: gridSpacing
            ) {
              videoList
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 12)

            // 底部状态
            if viewModel.isLoadingMore {
              ProgressView()
                .padding()
            } else if !viewModel.hasMore && !viewModel.videos.isEmpty {
              Text("已加载全部")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
            }
          }
          .refreshable {
            await viewModel.refresh()
          }
        }
      }
    }
    .navigationTitle(folder.title)
    .navigationBarTitleDisplayMode(.inline)
    .secondaryPageTabBarHidden()
    .navigationDestination(for: FavDataIOS.self) { video in
      // 根据视频类型导航到不同页面
      if video.ogv != nil {
        // OGV内容（番剧、影视等）暂时使用占位视图
        Text("OGV详情页待实现")
          .navigationTitle(video.title)
      } else {
        // 普通视频
        VideoDetailView(aid: video.id)
      }
    }
    .task {
      if viewModel.videos.isEmpty {
        await viewModel.loadVideos()
      }
    }
  }

  // MARK: - Grid Layout

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

  // MARK: - Video List Content

  @ViewBuilder
  private var videoList: some View {
    ForEach(viewModel.videos) { video in
      NavigationLink(value: video) {
        VideoCard(video: video)
      }
      .buttonStyle(.plain)
      .onAppear {
        // 检测滚动到底部，加载更多
        if video.id == viewModel.videos.last?.id {
          Task {
            await viewModel.loadMore()
          }
        }
      }
    }
  }

}

#Preview {
  NavigationStack {
    FavoriteFolderView(
      folder: FavListDataIOS(
        id: 1,
        title: "测试收藏夹",
        mediaCount: 42,
        isCreatedBySelf: true
      )
    )
  }
}
