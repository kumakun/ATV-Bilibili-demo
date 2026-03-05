//
//  WatchHistoryViewModel.swift
//  BilibiliLive-iOS
//
//  Created by iOS Implementation on 2026/3/5.
//

import Foundation
import Observation

@MainActor
@Observable
final class WatchHistoryViewModel {
  var items: [HistoryItem] = []
  var isLoading = false
  var errorMessage: String?

  func load() async {
    guard !isLoading else { return }
    isLoading = true
    errorMessage = nil

    do {
      items = try await ApiRequest.requestHistory()
    } catch {
      errorMessage = "加载历史记录失败"
    }

    isLoading = false
  }

  func refresh() async {
    await load()
  }

  func progressText(for item: HistoryItem) -> String {
    guard let progress = item.progress, let duration = item.duration, duration > 0 else {
      return "未记录进度"
    }
    let percent = Int(Double(progress) / Double(duration) * 100)
    return "已看 \(max(0, min(100, percent)))%"
  }

  func relativeTimeText(for item: HistoryItem) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: item.viewAtDate, relativeTo: Date())
  }
}
