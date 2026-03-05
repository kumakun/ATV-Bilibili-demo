//
//  FollowBangumiViewModel.swift
//  BilibiliLive-iOS
//
//  Created on 2026/3/5.
//

import Foundation

@Observable
final class FollowBangumiViewModel {
  var animeItems: [BangumiItem] = []
  var dramaItems: [BangumiItem] = []
  var selectedType: BangumiType = .anime
  var isLoading = false
  var errorMessage: String?

  // 分页
  var animePage = 1
  var dramaPage = 1
  var animeHasMore = true
  var dramaHasMore = true
  var isLoadingMore = false

  enum BangumiType: Int {
    case anime = 1
    case drama = 2
  }

  var currentItems: [BangumiItem] {
    selectedType == .anime ? animeItems : dramaItems
  }

  var currentHasMore: Bool {
    selectedType == .anime ? animeHasMore : dramaHasMore
  }

  @MainActor
  func loadInitial() async {
    guard !isLoading else { return }
    isLoading = true
    errorMessage = nil

    do {
      let items = try await ApiRequest.requestFollowBangumi(type: selectedType.rawValue, page: 1)

      if selectedType == .anime {
        animeItems = items
        animePage = 1
        animeHasMore = items.count >= 20
      } else {
        dramaItems = items
        dramaPage = 1
        dramaHasMore = items.count >= 20
      }
    } catch {
      errorMessage = "加载失败: \(error.localizedDescription)"
      print("Failed to load bangumi: \(error)")
    }

    isLoading = false
  }

  @MainActor
  func refresh() async {
    if selectedType == .anime {
      animeItems = []
      animePage = 1
      animeHasMore = true
    } else {
      dramaItems = []
      dramaPage = 1
      dramaHasMore = true
    }
    await loadInitial()
  }

  @MainActor
  func loadMoreIfNeeded(currentItem: BangumiItem?) async {
    guard let currentItem = currentItem else { return }

    let items = currentItems
    let thresholdIndex =
      items.index(items.endIndex, offsetBy: -5, limitedBy: items.startIndex) ?? items.startIndex

    if let currentIndex = items.firstIndex(where: { $0.id == currentItem.id }),
      currentIndex >= thresholdIndex,
      currentHasMore,
      !isLoadingMore
    {
      await loadMore()
    }
  }

  @MainActor
  private func loadMore() async {
    guard !isLoadingMore, currentHasMore else { return }
    isLoadingMore = true

    let nextPage = selectedType == .anime ? animePage + 1 : dramaPage + 1

    do {
      let items = try await ApiRequest.requestFollowBangumi(
        type: selectedType.rawValue, page: nextPage)

      if selectedType == .anime {
        animeItems.append(contentsOf: items)
        animePage = nextPage
        animeHasMore = items.count >= 20
      } else {
        dramaItems.append(contentsOf: items)
        dramaPage = nextPage
        dramaHasMore = items.count >= 20
      }
    } catch {
      print("Failed to load more bangumi: \(error)")
    }

    isLoadingMore = false
  }

  @MainActor
  func switchType(to type: BangumiType) async {
    guard selectedType != type else { return }
    selectedType = type

    // 如果该类型还没有数据，则加载
    if currentItems.isEmpty {
      await loadInitial()
    }
  }
}
