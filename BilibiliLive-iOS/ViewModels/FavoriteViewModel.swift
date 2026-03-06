//
//  FavoriteViewModel.swift
//  BilibiliLive-iOS
//
//  Created on 2026/3/6.
//

import Foundation

@MainActor
@Observable
final class FavoriteViewModel {
  // MARK: - Properties

  var folders: [FavListDataIOS] = []
  var isLoading = false
  var errorMessage: String?

  // MARK: - Methods

  func loadFolders() async {
    // 检查登录状态
    guard AccountManagerIOS.shared.isLoggedIn else {
      errorMessage = "请先登录"
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      // 加载用户自建收藏夹
      var allFolders = try await WebRequest.requestFavVideosList()

      // 加载用户收藏的订阅收藏夹
      let collectedFolders = try await WebRequest.requestFavFolderCollectedList()

      // 过滤掉 mid 为 0 的订阅收藏夹（无效数据）
      let validCollectedFolders = collectedFolders.filter { $0.mid != nil && $0.mid != 0 }

      // 合并结果
      allFolders.append(contentsOf: validCollectedFolders)

      folders = allFolders
    } catch let error as RequestError {
      errorMessage = handleError(error)
    } catch {
      errorMessage = "加载失败：\(error.localizedDescription)"
    }

    isLoading = false
  }

  func refresh() async {
    folders = []
    await loadFolders()
  }

  // MARK: - Private Methods

  private func handleError(_ error: RequestError) -> String {
    switch error {
    case .networkFail:
      return "网络连接失败，请检查网络设置"
    case .statusFail(let code, let message):
      if code == -1 {
        return "请先登录"
      }
      return "请求失败：\(message)"
    case .decodeFail(let message):
      return "数据解析失败：\(message)"
    }
  }
}
