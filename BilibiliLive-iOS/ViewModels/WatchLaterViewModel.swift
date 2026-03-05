//
//  WatchLaterViewModel.swift
//  BilibiliLive-iOS
//
//  Created on 2026/3/5.
//

import Foundation

@Observable
final class WatchLaterViewModel {
  var watchLaterItems: [WatchLaterItem] = []
  var isLoading = false
  var errorMessage: String?

  @MainActor
  func load() async {
    guard !isLoading else { return }
    isLoading = true
    errorMessage = nil

    do {
      let items = try await ApiRequest.requestToView()
      self.watchLaterItems = items
    } catch {
      errorMessage = "加载失败: \(error.localizedDescription)"
      print("Failed to load watch later items: \(error)")
    }

    isLoading = false
  }

  @MainActor
  func refresh() async {
    watchLaterItems = []
    await load()
  }

  @MainActor
  func delete(item: WatchLaterItem) async throws {
    guard let csrf = CookieHandler.shared.csrf() else {
      throw RequestError.statusFail(code: -1, message: "未找到 CSRF token")
    }
    try await ApiRequest.deleteToView(aid: item.aid, csrf: csrf)
    // 从列表中移除
    watchLaterItems.removeAll { $0.aid == item.aid }
  }

  // 格式化时长 (例如: "12:34" 或 "1:23:45")
  func durationText(for item: WatchLaterItem) -> String {
    let totalSeconds = item.duration
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%d:%02d", minutes, seconds)
    }
  }

  // 格式化发布时间
  func publishDateText(for item: WatchLaterItem) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(item.pubdate))
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: date, relativeTo: Date())
  }
}
