//
//  FollowViewModel.swift
//  BilibiliLive-iOS
//
//  Created on 2026/3/6.
//

import Foundation
import Observation

@MainActor
@Observable
final class FollowViewModel {
  var feeds: [DynamicFeedData] = []
  var isLoading = false
  var isLoadingMore = false
  var errorMessage: String?
  var hasMore = true
  var lastOffset: String = ""

  private var page = 1

  var videoFeeds: [DynamicFeedData] {
    feeds.filter { $0.aid != 0 || $0.modules.moduleDynamic.major?.pgc != nil }
  }

  func loadInitial() async {
    guard !isLoading else { return }

    isLoading = true
    errorMessage = nil
    page = 1
    lastOffset = ""

    do {
      let result = try await WebRequest.requestFollowsFeed(offset: "", page: page)
      feeds = result.items
      lastOffset = result.offset
      hasMore = result.hasMore
    } catch {
      errorMessage = "加载失败：\(error.localizedDescription)"
    }

    isLoading = false
  }

  func refresh() async {
    await loadInitial()
  }

  func loadMore() async {
    guard !isLoadingMore, !isLoading, hasMore else { return }

    isLoadingMore = true
    page += 1

    do {
      let result = try await WebRequest.requestFollowsFeed(offset: lastOffset, page: page)
      feeds.append(contentsOf: result.items)
      lastOffset = result.offset
      hasMore = result.hasMore
    } catch {
      page -= 1
      errorMessage = "加载更多失败"
    }

    isLoadingMore = false
  }

  func loadMoreIfNeeded(currentFeed: DynamicFeedData) async {
    guard let lastFeed = videoFeeds.last else { return }
    guard currentFeed.id == lastFeed.id else { return }

    await loadMore()
  }
}
