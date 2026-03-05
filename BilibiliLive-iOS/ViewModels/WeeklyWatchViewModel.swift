//
//  WeeklyWatchViewModel.swift
//  BilibiliLive-iOS
//
//  Created on 2026/3/5.
//

import Foundation

@Observable
final class WeeklyWatchViewModel {
  var weeklyList: [WeeklyList] = []
  var selectedWeekly: WeeklyList?
  var weeklyVideos: [WeeklyVideo] = []
  var isLoadingList = false
  var isLoadingVideos = false
  var errorMessage: String?

  @MainActor
  func loadWeeklyList() async {
    guard !isLoadingList else { return }
    isLoadingList = true
    errorMessage = nil

    do {
      let list = try await ApiRequest.requestWeeklyWatchList()
      self.weeklyList = list

      // 自动选择第一个
      if let first = list.first {
        selectedWeekly = first
        await loadWeeklyVideos(wid: first.number)
      }
    } catch {
      errorMessage = "加载失败: \(error.localizedDescription)"
      print("Failed to load weekly list: \(error)")
    }

    isLoadingList = false
  }

  @MainActor
  func loadWeeklyVideos(wid: Int) async {
    guard !isLoadingVideos else { return }
    isLoadingVideos = true

    do {
      let videos = try await ApiRequest.requestWeeklyWatch(wid: wid)
      self.weeklyVideos = videos
    } catch {
      errorMessage = "加载视频失败: \(error.localizedDescription)"
      print("Failed to load weekly videos: \(error)")
    }

    isLoadingVideos = false
  }

  @MainActor
  func selectWeekly(_ weekly: WeeklyList) async {
    guard selectedWeekly?.number != weekly.number else { return }
    selectedWeekly = weekly
    weeklyVideos = []
    await loadWeeklyVideos(wid: weekly.number)
  }

  @MainActor
  func refresh() async {
    weeklyList = []
    selectedWeekly = nil
    weeklyVideos = []
    await loadWeeklyList()
  }

  // 格式化播放数
  func formatCount(_ count: Int) -> String {
    if count >= 10000 {
      return String(format: "%.1f万", Double(count) / 10000.0)
    } else {
      return "\(count)"
    }
  }
}
