//
//  VideoDetailViewModel.swift
//  BilibiliLive-iOS
//
//  Created by GitHub Copilot on 2026/3/6.
//

import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class VideoDetailViewModel {
  // MARK: - State Properties

  var videoDetail: VideoDetail?
  var isLoading = false
  var errorMessage: String?

  // 播放相关
  var playURL: URL?
  var player: AVPlayer?

  // 互动状态
  var isLiked = false
  var coinCount = 0
  var isFavorited = false
  var isFollowing = false

  // 分P相关
  var currentPageIndex = 0
  var pages: [VideoPage] = []

  // 视频ID
  private let aid: Int
  private var cid: Int

  // MARK: - Initialization

  init(aid: Int, cid: Int = 0) {
    self.aid = aid
    self.cid = cid
  }

  // MARK: - Load Video Detail

  func loadVideoDetail() async {
    guard !isLoading else { return }

    isLoading = true
    errorMessage = nil

    do {
      let detail = try await WebRequest.requestVideoDetail(aid: aid)
      videoDetail = detail

      // 如果cid为0，使用第一个分P的cid
      if cid == 0, let firstPage = detail.View.pages?.first {
        cid = firstPage.cid
      }

      // 设置分P列表
      pages = detail.View.pages ?? []
      if !pages.isEmpty {
        currentPageIndex = pages.firstIndex(where: { $0.cid == cid }) ?? 0
      }

      // 设置关注状态
      isFollowing = detail.Card.following

      // 加载互动状态
      await loadInteractionStatus()

    } catch {
      errorMessage = "加载视频详情失败：\(error.localizedDescription)"
    }

    isLoading = false
  }

  // MARK: - Load Play URL

  func loadPlayUrl() async {
    guard cid > 0 else {
      print("❌ VideoDetailViewModel: cid is 0, cannot load play URL")
      return
    }

    print("📹 VideoDetailViewModel: Loading play URL for aid=\(aid), cid=\(cid)")

    do {
      let playURLInfo = try await WebRequest.requestPlayUrl(aid: aid, cid: cid)
      print("✅ VideoDetailViewModel: Got play URL info, quality=\(playURLInfo.quality)")
      print("   Video streams: \(playURLInfo.dash?.video.count ?? 0)")
      print("   Audio streams: \(playURLInfo.dash?.audio?.count ?? 0)")

      // 使用DASH播放器创建支持音视频分离的播放器
      if let (videoURL, audioURL) = DASHVideoPlayer.extractBestStreams(from: playURLInfo) {
        playURL = videoURL
        
        // 创建DASH播放器（合并音视频），传递aid用于防盗链验证
        if let dashPlayer = await DASHVideoPlayer.createPlayer(videoURL: videoURL, audioURL: audioURL, aid: aid) {
          player = dashPlayer
          print("✅ VideoDetailViewModel: DASH player created successfully")
          
          // 自动开始播放
          player?.play()
          print("✅ VideoDetailViewModel: Player.play() called")
        } else {
          print("⚠️ VideoDetailViewModel: Failed to create DASH player, trying direct fallback")
          try await loadDirectPlayFallback()
        }
      } else {
        print("⚠️ VideoDetailViewModel: Failed to extract DASH streams, trying direct fallback")
        try await loadDirectPlayFallback()
      }
    } catch {
      print("❌ VideoDetailViewModel: Failed to load play URL: \(error)")
      do {
        print("⚠️ VideoDetailViewModel: Trying direct fallback after play URL error")
        try await loadDirectPlayFallback()
      } catch {
        errorMessage = "加载播放地址失败：\(error.localizedDescription)"
      }
    }
  }

  private func loadDirectPlayFallback() async throws {
    let directPlayInfo = try await WebRequest.requestDirectPlayUrl(aid: aid, cid: cid)

    guard let directURL = directPlayInfo.bestDirectPlayURL else {
      print("❌ VideoDetailViewModel: Direct fallback URL not found")
      errorMessage = "无法获取兼容的视频播放地址"
      return
    }

    playURL = directURL
    let directPlayer = DASHVideoPlayer.createDirectPlayer(url: directURL, aid: aid)
    player = directPlayer
    print("✅ VideoDetailViewModel: Direct fallback player created successfully")
    player?.play()
    print("✅ VideoDetailViewModel: Direct fallback Player.play() called")
  }

  // MARK: - Load Interaction Status

  private func loadInteractionStatus() async {
    // 并行加载点赞、投币、收藏状态
    async let likeStatus = try? ApiRequest.requestLikeStatus(aid: aid)
    async let coinStatus = try? ApiRequest.requestCoinStatus(aid: aid)
    async let favStatus = try? ApiRequest.requestFavoriteStatus(aid: aid)

    let (like, coin, fav) = await (likeStatus, coinStatus, favStatus)

    isLiked = like ?? false
    coinCount = coin ?? 0
    isFavorited = fav ?? false
  }

  // MARK: - Like Action

  func toggleLike() async {
    // 检查登录状态
    guard AccountManagerIOS.shared.isLoggedIn else {
      errorMessage = "请先登录后再进行点赞操作"
      return
    }

    let newLikeState = !isLiked

    do {
      let success = try await ApiRequest.requestLike(aid: aid, like: newLikeState)
      if success {
        isLiked = newLikeState
        // 注意：统计数据的更新需要从服务器重新加载或使用可变结构
      }
    } catch {
      errorMessage = "点赞操作失败"
    }
  }

  // MARK: - Coin Action

  func sendCoin(num: Int) async {
    // 检查登录状态
    guard AccountManagerIOS.shared.isLoggedIn else {
      errorMessage = "请先登录后再进行投币操作"
      return
    }

    guard num > 0, coinCount == 0 else { return }

    do {
      let success = try await ApiRequest.requestCoin(aid: aid, num: num)
      if success {
        coinCount = num
        // 注意：统计数据的更新需要从服务器重新加载或使用可变结构
      }
    } catch {
      errorMessage = "投币失败"
    }
  }

  // MARK: - Favorite Action

  func toggleFavorite(mediaId: Int = 0) async {
    // 检查登录状态
    guard AccountManagerIOS.shared.isLoggedIn else {
      errorMessage = "请先登录后再进行收藏操作"
      return
    }

    // 简化版：使用默认收藏夹（mediaId=0时需要获取用户的默认收藏夹）
    // 完整版需要显示收藏夹选择器

    if isFavorited {
      // 取消收藏（需要收藏夹ID列表）
      errorMessage = "取消收藏功能待实现"
    } else {
      // 收藏
      if mediaId > 0 {
        do {
          let success = try await ApiRequest.requestFavorite(aid: aid, mid: mediaId)
          if success {
            isFavorited = true
            // 注意：统计数据的更新需要从服务器重新加载或使用可变结构
          }
        } catch {
          errorMessage = "收藏失败"
        }
      } else {
        errorMessage = "请先选择收藏夹"
      }
    }
  }

  // MARK: - Follow Action

  func toggleFollow() async {
    // 检查登录状态
    guard AccountManagerIOS.shared.isLoggedIn else {
      errorMessage = "请先登录后再进行关注操作"
      return
    }

    guard let mid = videoDetail?.View.owner.mid else { return }

    let newFollowState = !isFollowing

    do {
      let success = try await ApiRequest.follow(mid: mid, follow: newFollowState)
      if success {
        isFollowing = newFollowState
      }
    } catch {
      errorMessage = "关注操作失败"
    }
  }

  // MARK: - Switch Episode

  func switchEpisode(to index: Int) async {
    guard index >= 0, index < pages.count else { return }

    currentPageIndex = index
    let page = pages[index]
    cid = page.cid

    // 停止当前播放
    player?.pause()
    player = nil
    playURL = nil

    // 加载新的播放地址
    await loadPlayUrl()
  }

  func switchToNextEpisode() async {
    let nextIndex = currentPageIndex + 1
    if nextIndex < pages.count {
      await switchEpisode(to: nextIndex)
    }
  }

  func switchToPreviousEpisode() async {
    let prevIndex = currentPageIndex - 1
    if prevIndex >= 0 {
      await switchEpisode(to: prevIndex)
    }
  }

  // MARK: - Play Progress

  func savePlayProgress(currentTime: TimeInterval) {
    // 保存播放进度到UserDefaults
    let key = "video_progress_\(aid)_\(cid)"
    UserDefaults.standard.set(currentTime, forKey: key)
  }

  func loadPlayProgress() -> TimeInterval? {
    let key = "video_progress_\(aid)_\(cid)"
    let progress = UserDefaults.standard.double(forKey: key)
    return progress > 0 ? progress : nil
  }

  func clearPlayProgress() {
    let key = "video_progress_\(aid)_\(cid)"
    UserDefaults.standard.removeObject(forKey: key)
  }

  // MARK: - Error Handling

  func clearError() {
    errorMessage = nil
  }

  // MARK: - Computed Properties

  var currentPage: VideoPage? {
    guard currentPageIndex >= 0, currentPageIndex < pages.count else { return nil }
    return pages[currentPageIndex]
  }

  var hasMultiplePages: Bool {
    pages.count > 1
  }

  var canPlayNext: Bool {
    currentPageIndex < pages.count - 1
  }

  var canPlayPrevious: Bool {
    currentPageIndex > 0
  }
}
