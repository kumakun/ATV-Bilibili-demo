//
//  VideoDetailView.swift
//  BilibiliLive-iOS
//
//  Created by GitHub Copilot on 2026/3/6.
//

import SwiftUI

struct VideoDetailView: View {
  let aid: Int
  let cid: Int

  @State private var viewModel: VideoDetailViewModel
  @State private var showCoinAlert = false
  @State private var shareItem: ShareItem?

  init(aid: Int, cid: Int = 0) {
    self.aid = aid
    self.cid = cid
    _viewModel = State(initialValue: VideoDetailViewModel(aid: aid, cid: cid))
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        // 视频播放器
        VideoPlayerView(player: viewModel.player)

        if viewModel.isLoading {
          ProgressView("加载中...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage {
          VStack(spacing: 12) {
            Text(errorMessage)
              .foregroundStyle(.secondary)
            Button("重试") {
              Task {
                await viewModel.loadVideoDetail()
                await viewModel.loadPlayUrl()
              }
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let videoDetail = viewModel.videoDetail {
          // 视频信息
          VideoInfoSection(videoInfo: videoDetail.View)

          // 统计数据
          VideoStatsView(stat: videoDetail.View.stat)

          // UP主信息
          UploaderInfoView(
            owner: videoDetail.View.owner,
            isFollowing: viewModel.isFollowing,
            onFollowTap: {
              Task {
                await viewModel.toggleFollow()
              }
            }
          )

          // 操作栏
          VideoActionBar(
            isLiked: viewModel.isLiked,
            coinCount: viewModel.coinCount,
            isFavorited: viewModel.isFavorited,
            onLikeTap: {
              Task {
                await viewModel.toggleLike()
              }
            },
            onCoinTap: {
              showCoinAlert = true
            },
            onFavoriteTap: {
              Task {
                await viewModel.toggleFavorite()
              }
            },
            onShareTap: {
              if let bvid = videoDetail.View.bvid {
                shareItem = ShareItem(text: "https://www.bilibili.com/video/\(bvid)")
              }
            }
          )

          // 简介
          if let desc = videoDetail.View.desc, !desc.isEmpty {
            VideoDescriptionSection(description: desc)
          }

          // 分P列表
          if viewModel.hasMultiplePages {
            VideoEpisodesSection(
              pages: viewModel.pages,
              currentPageIndex: viewModel.currentPageIndex,
              onPageTap: { index in
                Task {
                  await viewModel.switchEpisode(to: index)
                }
              }
            )
          }
        }
      }
      .padding(.vertical)
    }
    .navigationTitle("视频详情")
    .navigationBarTitleDisplayMode(.inline)
    .refreshable {
      await viewModel.loadVideoDetail()
      await viewModel.loadPlayUrl()
    }
    .alert("投币", isPresented: $showCoinAlert) {
      Button("取消", role: .cancel) {}
      Button("投1个币") {
        Task {
          await viewModel.sendCoin(num: 1)
        }
      }
      Button("投2个币") {
        Task {
          await viewModel.sendCoin(num: 2)
        }
      }
    } message: {
      Text("选择要投币的数量")
    }
    .sheet(item: $shareItem) { item in
      ShareSheet(items: [item.text])
    }
    .task {
      await viewModel.loadVideoDetail()
      await viewModel.loadPlayUrl()
    }
  }
}

// MARK: - Share Item

struct ShareItem: Identifiable {
  let id = UUID()
  let text: String
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
  let items: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: items, applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
  NavigationStack {
    VideoDetailView(aid: 123456)
  }
}
