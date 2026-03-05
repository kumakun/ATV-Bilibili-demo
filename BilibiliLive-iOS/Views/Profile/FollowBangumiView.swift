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
                GridItem(.adaptive(minimum: 150), spacing: 12)
              ], spacing: 16
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

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // 封面
      ZStack(alignment: .topTrailing) {
        AsyncImage(url: item.coverURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Color.gray.opacity(0.2)
        }
        .frame(height: 200)
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
  }
}

#Preview {
  NavigationStack {
    FollowBangumiView()
  }
}
