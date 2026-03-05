//
//  FollowUpsViewModel.swift
//  BilibiliLive-iOS
//
//  Created by iOS Implementation on 2026/3/5.
//

import Foundation
import Observation

@MainActor
@Observable
final class FollowUpsViewModel {
  var users: [FollowingUser] = []
  var isLoading = false
  var isLoadingMore = false
  var errorMessage: String?
  var hasMore = true

  private var page = 1

  func loadInitial() async {
    guard !isLoading else { return }

    isLoading = true
    errorMessage = nil
    page = 1

    do {
      let result = try await ApiRequest.requestFollowingUps(page: page)
      users = result
      hasMore = result.count >= 40
    } catch {
      errorMessage = "加载关注列表失败"
    }

    isLoading = false
  }

  func refresh() async {
    await loadInitial()
  }

  func loadMoreIfNeeded(currentUser: FollowingUser) async {
    guard hasMore, !isLoadingMore, !isLoading else { return }
    guard users.last?.id == currentUser.id else { return }

    isLoadingMore = true
    page += 1

    do {
      let result = try await ApiRequest.requestFollowingUps(page: page)
      users.append(contentsOf: result)
      hasMore = result.count >= 40
    } catch {
      page -= 1
      errorMessage = "加载更多失败"
    }

    isLoadingMore = false
  }
}
