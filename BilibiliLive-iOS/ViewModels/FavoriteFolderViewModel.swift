//
//  FavoriteFolderViewModel.swift
//  BilibiliLive-iOS
//
//  Created on 2026/3/6.
//

import Foundation

@MainActor
@Observable
final class FavoriteFolderViewModel {
  // MARK: - Properties

  let folder: FavListDataIOS
  var videos: [FavDataIOS] = []
  var currentPage = 1
  var hasMore = true
  var isLoading = false
  var isLoadingMore = false
  var errorMessage: String?

  // MARK: - Initialization

  init(folder: FavListDataIOS) {
    self.folder = folder
  }

  // MARK: - Methods

  func loadVideos() async {
    guard !isLoading else { return }

    isLoading = true
    errorMessage = nil
    currentPage = 1

    do {
      let newVideos = try await fetchVideos(page: currentPage)
      videos = newVideos

      // 判断是否还有更多数据（每页20条）
      hasMore = newVideos.count >= 20
    } catch let error as RequestError {
      errorMessage = handleError(error)
    } catch {
      errorMessage = "加载失败：\(error.localizedDescription)"
    }

    isLoading = false
  }

  func loadMore() async {
    guard !isLoadingMore, hasMore else { return }

    isLoadingMore = true
    currentPage += 1

    do {
      let newVideos = try await fetchVideos(page: currentPage)
      videos.append(contentsOf: newVideos)

      // 如果返回的数据少于20条，说明没有更多了
      hasMore = newVideos.count >= 20
    } catch let error as RequestError {
      errorMessage = handleError(error)
      // 加载失败，回退页码
      currentPage -= 1
    } catch {
      errorMessage = "加载失败：\(error.localizedDescription)"
      currentPage -= 1
    }

    isLoadingMore = false
  }

  func refresh() async {
    videos = []
    currentPage = 1
    hasMore = true
    await loadVideos()
  }

  func navigateToVideo(_ video: FavDataIOS) {
    // TODO: 待视频详情页实现后连接
    if let ogv = video.ogv {
      print("Navigate to OGV content with season_id: \(ogv.seasonId)")
    } else {
      print("Navigate to video with aid: \(video.id)")
    }
  }

  // MARK: - Private Methods

  private func fetchVideos(page: Int) async throws -> [FavDataIOS] {
    if folder.isCreatedBySelf {
      // 用户自建收藏夹
      return try await WebRequest.requestFavVideos(mediaId: String(folder.id), page: page)
    } else {
      // 用户收藏的订阅收藏夹
      return try await WebRequest.requestFavSeason(seasonId: String(folder.id), page: page)
    }
  }

  private func handleError(_ error: RequestError) -> String {
    switch error {
    case .networkFail:
      return "网络连接失败，请检查网络设置"
    case .statusFail(let code, let message):
      return "请求失败 (\(code))：\(message)"
    case .decodeFail(let message):
      return "数据解析失败：\(message)"
    }
  }
}
