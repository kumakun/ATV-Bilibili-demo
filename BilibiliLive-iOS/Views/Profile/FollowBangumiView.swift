//
//  FollowBangumiView.swift
//  BilibiliLive-iOS
//
//  Created on 2026/3/5.
//

import SwiftUI

struct FollowBangumiView: View {
  @State private var viewModel = FollowBangumiViewModel()

  var body: some View {
    VStack(spacing: 0) {
      // 分类标签切换
      Picker(
        "类型",
        selection: Binding(
          get: { viewModel.selectedType },
          set: { newValue in
            Task {
              await viewModel.switchType(to: newValue)
            }
          }
        )
      ) {
        Text("番剧").tag(FollowBangumiViewModel.BangumiType.anime)
        Text("影视").tag(FollowBangumiViewModel.BangumiType.drama)
      }
      .pickerStyle(.segmented)
      .padding(.horizontal)
      .padding(.vertical, 8)

      // 内容区域
      Group {
        if viewModel.isLoading && viewModel.currentItems.isEmpty {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage, viewModel.currentItems.isEmpty {
          VStack(spacing: 16) {
            Text(errorMessage)
              .foregroundColor(.secondary)
            Button("重试") {
              Task {
                await viewModel.loadInitial()
              }
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.currentItems.isEmpty {
          Text("暂无追番")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          ScrollView {
            LazyVGrid(
              columns: [
                GridItem(.adaptive(minimum: 100, maximum: 190), spacing: 12, alignment: .top)
              ], spacing: 20
            ) {
              ForEach(viewModel.currentItems) { item in
                // TODO: Add bangumi detail navigation when implemented
                BangumiCard(item: item)
                  .onAppear {
                    Task {
                      await viewModel.loadMoreIfNeeded(currentItem: item)
                    }
                  }
              }

              // 加载更多指示器
              if viewModel.isLoadingMore {
                ProgressView()
                  .frame(maxWidth: .infinity)
                  .gridCellColumns(2)
                  .padding()
              }
            }
            .padding(.horizontal)
            .padding(.top, 8)
          }
          .refreshable {
            await viewModel.refresh()
          }
        }
      }
    }
    .navigationTitle("追番追剧")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.loadInitial()
    }
  }
}

struct BangumiCard: View {
  let item: BangumiItem

  private let coverAspectRatio: CGFloat = 3.0 / 4.0

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // 封面
      ZStack(alignment: .topTrailing) {
        GeometryReader { geometry in
          AsyncImage(url: item.coverURL) { image in
            image
              .resizable()
              .scaledToFill()
              .frame(width: geometry.size.width, height: geometry.size.height)
              .clipped()
          } placeholder: {
            Color.gray.opacity(0.2)
          }
        }
        .aspectRatio(coverAspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))

        // 更新标记
        if item.isUpdatedToday {
          Text("更新")
            .font(.system(size: 11))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.red)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(6)
        }
      }

      // 标题
      Text(item.title)
        .font(.system(size: 14))
        .lineLimit(2)
        .foregroundColor(.primary)

      // 进度和最新集
      VStack(alignment: .leading, spacing: 2) {
        if let progress = item.progress, !progress.isEmpty {
          Text(progress)
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }

        if let newEp = item.newEp, let indexShow = newEp.indexShow, !indexShow.isEmpty {
          Text("更新至 \(indexShow)")
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }
      }
    }
    .frame(maxWidth: 190)
  }
}

// MARK: - Preview Mock Card for better visualization
struct PreviewBangumiCard: View {
  let item: BangumiItem
  let color: Color

  private let coverAspectRatio: CGFloat = 3.0 / 4.0

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // 封面 - 使用纯色替代网络图片
      ZStack(alignment: .topTrailing) {
        GeometryReader { geometry in
          ZStack {
            color
            Image(systemName: "tv")
              .font(.system(size: 40))
              .foregroundColor(.white.opacity(0.5))
          }
          .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(coverAspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))

        // 更新标记
        if item.isUpdatedToday {
          Text("更新")
            .font(.system(size: 11))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.red)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(6)
        }
      }

      // 标题
      Text(item.title)
        .font(.system(size: 14))
        .lineLimit(2)
        .foregroundColor(.primary)

      // 进度和最新集
      VStack(alignment: .leading, spacing: 2) {
        if let progress = item.progress, !progress.isEmpty {
          Text(progress)
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }

        if let newEp = item.newEp, let indexShow = newEp.indexShow, !indexShow.isEmpty {
          Text("更新至 \(indexShow)")
            .font(.system(size: 12))
            .foregroundColor(.secondary)
        }
      }
    }
    .frame(maxWidth: 190)
  }
}

#Preview("BangumiCard Grid") {
  let mockItems = [
    BangumiItem(
      seasonId: 1,
      mediaId: 101,
      title: "肥志百科",
      cover: "https://i0.hdslb.com/bfs/bangumi/image/9d0b8e094fbfb8d9ec794690c28bc0844ba19aba.jpg",
      progress: "看到第12话",
      newEp: NewEpisode(
        indexShow: "第28话",
        cover: "http://i0.hdslb.com/bfs/archive/16c6a8f8c204d2ece73f33eea3d3396cf8bdc58b.jpg",
        pubTime: "2026-03-06 12:00:00"
      )
    ),
    BangumiItem(
      seasonId: 2,
      mediaId: 102,
      title: "中国奇谭2",
      cover: "https://i0.hdslb.com/bfs/bangumi/image/d074cac4c8d9e28fee054ab490aadc2dc1df9062.png",
      progress: "看到第8话",
      newEp: NewEpisode(
        indexShow: "第12话",
        cover: "http://i0.hdslb.com/bfs/archive/c1d1e7258bb337c9ec5af363312328f0ba2b7e01.jpg",
        pubTime: "2026-03-05 20:00:00"
      )
    ),
    BangumiItem(
      seasonId: 3,
      mediaId: 103,
      title: "名侦探柯南（中配）",
      cover: "http://i0.hdslb.com/bfs/bangumi/image/38e2a273f528fd01c34f1fc4df0f69c64487efad.png",
      progress: nil,
      newEp: NewEpisode(
        indexShow: "第13话",
        cover: "http://i0.hdslb.com/bfs/archive/316f03ef61f8f2437540489d184d78c13c38b598.png",
        pubTime: "2026-03-04 18:00:00"
      )
    ),
    BangumiItem(
      seasonId: 4,
      mediaId: 104,
      title: "葬送的芙莉莲 中配版",
      cover: "https://i0.hdslb.com/bfs/bangumi/image/faf410ab7dd2fbf811dbacfbca9003da0a3903d0.png",
      progress: "看到第20话",
      newEp: NewEpisode(
        indexShow: "第23话",
        cover: "http://i0.hdslb.com/bfs/archive/26e33625761ab5c63e32614d44136ea30fcc28d0.png",
        pubTime: "2026-03-01 22:00:00"
      )
    ),
    BangumiItem(
      seasonId: 5,
      mediaId: 105,
      title: "乐高悟空小侠之英雄出世",
      cover: "https://i0.hdslb.com/bfs/bangumi/image/4acb0b36375ff87794452993f856645311c67b1c.png",
      progress: "看到第15话",
      newEp: NewEpisode(
        indexShow: "第24话",
        cover: "http://i0.hdslb.com/bfs/archive/3ae000a47e0167ce42c1aa746cf6dfb9949a7cd2.png",
        pubTime: "2026-03-06 10:00:00"
      )
    ),
    BangumiItem(
      seasonId: 6,
      mediaId: 106,
      title: "胆大党 第二季 中配版",
      cover: "https://i0.hdslb.com/bfs/bangumi/image/c33526ff1994a0740bf9e0baf5268fd534b88b53.png",
      progress: "已看完",
      newEp: NewEpisode(
        indexShow: "第13话",
        cover: "http://i0.hdslb.com/bfs/archive/4a1672d8fb63b7d9cd1f632603afb7400afb11b1.png",
        pubTime: "2026-02-28 20:00:00"
      )
    ),
  ]

  ScrollView {
    LazyVGrid(
      columns: [
        GridItem(.adaptive(minimum: 100, maximum: 190), spacing: 12, alignment: .top)
      ], spacing: 20
    ) {
      ForEach(mockItems) { item in
        BangumiCard(item: item)
      }
    }
    .padding(.horizontal)
  }
}

#Preview("Complete View") {
  let mockItems = [
    BangumiItem(
      seasonId: 1,
      mediaId: 101,
      title: "肥志百科",
      cover: "https://i0.hdslb.com/bfs/bangumi/image/9d0b8e094fbfb8d9ec794690c28bc0844ba19aba.jpg",
      progress: "看到第12话",
      newEp: NewEpisode(
        indexShow: "第28话",
        cover: "http://i0.hdslb.com/bfs/archive/16c6a8f8c204d2ece73f33eea3d3396cf8bdc58b.jpg",
        pubTime: "2026-03-06 12:00:00"
      )
    ),
    BangumiItem(
      seasonId: 2,
      mediaId: 102,
      title: "中国奇谭2",
      cover: "https://i0.hdslb.com/bfs/bangumi/image/d074cac4c8d9e28fee054ab490aadc2dc1df9062.png",
      progress: "看到第8话",
      newEp: NewEpisode(
        indexShow: "第12话",
        cover: "http://i0.hdslb.com/bfs/archive/c1d1e7258bb337c9ec5af363312328f0ba2b7e01.jpg",
        pubTime: "2026-03-05 20:00:00"
      )
    ),
    BangumiItem(
      seasonId: 3,
      mediaId: 103,
      title: "名侦探柯南（中配）",
      cover: "http://i0.hdslb.com/bfs/bangumi/image/38e2a273f528fd01c34f1fc4df0f69c64487efad.png",
      progress: nil,
      newEp: NewEpisode(
        indexShow: "第13话",
        cover: "http://i0.hdslb.com/bfs/archive/316f03ef61f8f2437540489d184d78c13c38b598.png",
        pubTime: "2026-03-04 18:00:00"
      )
    ),
    BangumiItem(
      seasonId: 4,
      mediaId: 104,
      title: "葬送的芙莉莲 中配版",
      cover: "https://i0.hdslb.com/bfs/bangumi/image/faf410ab7dd2fbf811dbacfbca9003da0a3903d0.png",
      progress: "看到第20话",
      newEp: NewEpisode(
        indexShow: "第23话",
        cover: "http://i0.hdslb.com/bfs/archive/26e33625761ab5c63e32614d44136ea30fcc28d0.png",
        pubTime: "2026-03-01 22:00:00"
      )
    ),
    BangumiItem(
      seasonId: 5,
      mediaId: 105,
      title: "乐高悟空小侠之英雄出世",
      cover: "https://i0.hdslb.com/bfs/bangumi/image/4acb0b36375ff87794452993f856645311c67b1c.png",
      progress: "看到第15话",
      newEp: NewEpisode(
        indexShow: "第24话",
        cover: "http://i0.hdslb.com/bfs/archive/3ae000a47e0167ce42c1aa746cf6dfb9949a7cd2.png",
        pubTime: "2026-03-06 10:00:00"
      )
    ),
    BangumiItem(
      seasonId: 6,
      mediaId: 106,
      title: "胆大党 第二季 中配版",
      cover: "https://i0.hdslb.com/bfs/bangumi/image/c33526ff1994a0740bf9e0baf5268fd534b88b53.png",
      progress: "已看完",
      newEp: NewEpisode(
        indexShow: "第13话",
        cover: "http://i0.hdslb.com/bfs/archive/4a1672d8fb63b7d9cd1f632603afb7400afb11b1.png",
        pubTime: "2026-02-28 20:00:00"
      )
    ),
  ]

  NavigationStack {
    VStack(spacing: 0) {
      // 分类标签切换
      Picker("类型", selection: .constant(0)) {
        Text("番剧").tag(0)
        Text("影视").tag(1)
      }
      .pickerStyle(.segmented)
      .padding(.horizontal)
      .padding(.vertical, 8)

      // 内容区域
      ScrollView {
        LazyVGrid(
          columns: [
            GridItem(.adaptive(minimum: 100, maximum: 190), spacing: 12, alignment: .top)
          ], spacing: 20
        ) {
          ForEach(mockItems) { item in
            BangumiCard(item: item)
          }
        }
        .padding(.horizontal)
        .padding(.top, 8)
      }
    }
    .navigationTitle("追番追剧")
    .navigationBarTitleDisplayMode(.inline)
  }
}
