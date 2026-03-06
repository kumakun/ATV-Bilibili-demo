//
//  FavoriteView.swift
//  BilibiliLive-iOS
//
//  Created by niuniu on 2026/3/5.
//

import SwiftUI

struct FavoriteView: View {
  @State private var viewModel = FavoriteViewModel()

  var body: some View {
    NavigationStack {
      Group {
        if !AccountManagerIOS.shared.isLoggedIn {
          // 未登录状态
          ContentUnavailableView(
            "需要登录",
            systemImage: "person.crop.circle.badge.exclamationmark",
            description: Text("请先登录后查看收藏")
          )
        } else if viewModel.isLoading && viewModel.folders.isEmpty {
          // 首次加载状态
          ProgressView("加载中...")
        } else if let error = viewModel.errorMessage {
          // 错误状态
          ContentUnavailableView(
            "加载失败",
            systemImage: "exclamationmark.triangle",
            description: Text(error)
          )
          .overlay(alignment: .bottom) {
            Button("重试") {
              Task {
                await viewModel.loadFolders()
              }
            }
            .buttonStyle(.borderedProminent)
            .padding()
          }
        } else if viewModel.folders.isEmpty {
          // 空状态
          ContentUnavailableView(
            "暂无收藏夹",
            systemImage: "folder.badge.questionmark",
            description: Text("你还没有创建或收藏任何收藏夹")
          )
        } else {
          // 正常列表展示
          ScrollView {
            LazyVStack(spacing: 16) {
              ForEach(viewModel.folders) { folder in
                NavigationLink(value: folder) {
                  FavoriteFolderCard(folder: folder)
                }
                .buttonStyle(.plain)
              }
            }
            .padding()
          }
          .refreshable {
            await viewModel.refresh()
          }
        }
      }
      .navigationDestination(for: FavListDataIOS.self) { folder in
        FavoriteFolderView(folder: folder)
      }
      .task {
        if viewModel.folders.isEmpty {
          await viewModel.loadFolders()
        }
      }
    }
  }
}

#Preview {
  FavoriteView()
}
