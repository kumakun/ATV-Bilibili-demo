//
//  DASHVideoPlayer.swift
//  BilibiliLive-iOS
//
//  Created by GitHub Copilot on 2026/3/6.
//

import AVFoundation
import Foundation
import ObjectiveC

/// DASH视频播放器管理器，用于处理B站的DASH格式视频（音视频分离）
class DASHVideoPlayer {
  private static var resourceLoaderAssociationKey: UInt8 = 0

  private static func assetOptions(for aid: Int) -> [String: Any] {
    let headers = [
      "Referer": "https://www.bilibili.com/video/av\(aid)",
      "User-Agent":
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15",
    ]

    return [
      "AVURLAssetHTTPHeaderFieldsKey": headers,
      AVURLAssetPreferPreciseDurationAndTimingKey: false,
    ]
  }

  static func createDirectPlayer(url: URL, aid: Int) -> AVPlayer {
    print("🎬 DASHVideoPlayer: Creating direct player")
    print("   URL: \(url.absoluteString.prefix(100))...")
    let asset = AVURLAsset(url: url, options: assetOptions(for: aid))
    let playerItem = AVPlayerItem(asset: asset)
    return AVPlayer(playerItem: playerItem)
  }

  static func createPlayer(from playURLInfo: VideoPlayURLInfo, aid: Int) async -> AVPlayer? {
    await createPlayer(from: playURLInfo, aid: aid, tier: .high)
  }

  static func createPlayer(
    from playURLInfo: VideoPlayURLInfo,
    aid: Int,
    tier: VideoPlaybackQualityTier
  ) async -> AVPlayer? {
    do {
      let selection = try DASHStreamSelection.select(from: playURLInfo, tier: tier)
      let resourceLoader = DASHResourceLoader(
        video: selection.video,
        audio: selection.audio,
        aid: aid
      )

      let asset = AVURLAsset(url: resourceLoader.playbackURL, options: assetOptions(for: aid))
      asset.resourceLoader.setDelegate(resourceLoader, queue: DispatchQueue(label: "bilibili.dash.loader"))
      let playerItem = AVPlayerItem(asset: asset)
      objc_setAssociatedObject(
        playerItem,
        &resourceLoaderAssociationKey,
        resourceLoader,
        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )

      return AVPlayer(playerItem: playerItem)
    } catch {
      print("❌ DASHVideoPlayer: Failed to create resource-loader player: \(error)")
      return nil
    }
  }

  /// 创建支持DASH格式的AVPlayer
  /// - Parameters:
  ///   - videoURL: 视频流URL
  ///   - audioURL: 音频流URL
  ///   - aid: 视频AV号，用于构建防盗链Referer
  /// - Returns: 配置好的AVPlayer实例
  static func createPlayer(videoURL: URL, audioURL: URL, aid: Int) async -> AVPlayer? {
    print("🎬 DASHVideoPlayer: Creating player with video and audio streams")
    print("   Video: \(videoURL.absoluteString.prefix(100))...")
    print("   Audio: \(audioURL.absoluteString.prefix(100))...")

    let options = assetOptions(for: aid)

    // 创建视频和音频的AVAsset，附带HTTP请求头
    let videoAsset = AVURLAsset(url: videoURL, options: options)
    let audioAsset = AVURLAsset(url: audioURL, options: options)

    // 创建AVMutableComposition来合并音视频
    let composition = AVMutableComposition()

    do {
      // 异步加载视频轨道
      print("🎬 DASHVideoPlayer: Loading video tracks...")
      let videoTracks = try await videoAsset.loadTracks(withMediaType: .video)

      guard let videoTrack = videoTracks.first else {
        print("❌ DASHVideoPlayer: No video track found")
        return nil
      }

      print("✅ DASHVideoPlayer: Video track loaded")

      let compositionVideoTrack = composition.addMutableTrack(
        withMediaType: .video,
        preferredTrackID: kCMPersistentTrackID_Invalid
      )

      let videoDuration = try await videoAsset.load(.duration)

      try compositionVideoTrack?.insertTimeRange(
        CMTimeRange(start: .zero, duration: videoDuration),
        of: videoTrack,
        at: .zero
      )

      print("✅ DASHVideoPlayer: Video track added to composition")

      // 异步加载音频轨道（尝试所有可用的音频流）
      print("🎬 DASHVideoPlayer: Loading audio tracks...")

      var audioAdded = false
      do {
        let audioTracks = try await audioAsset.loadTracks(withMediaType: .audio)

        if let audioTrack = audioTracks.first {
          print("✅ DASHVideoPlayer: Audio track loaded")

          let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
          )

          let audioDuration = try await audioAsset.load(.duration)

          try compositionAudioTrack?.insertTimeRange(
            CMTimeRange(start: .zero, duration: audioDuration),
            of: audioTrack,
            at: .zero
          )

          print("✅ DASHVideoPlayer: Audio track added to composition")
          audioAdded = true
        }
      } catch {
        print("⚠️ DASHVideoPlayer: Failed to load audio track: \(error)")
        print("⚠️ DASHVideoPlayer: Will play video without audio")
      }

      if !audioAdded {
        print("⚠️ DASHVideoPlayer: No audio available, creating video-only player")
      }

      // 创建AVPlayerItem和AVPlayer
      let playerItem = AVPlayerItem(asset: composition)
      let player = AVPlayer(playerItem: playerItem)

      print(
        "✅ DASHVideoPlayer: Player created successfully \(audioAdded ? "with audio" : "(video only)")"
      )
      return player

    } catch {
      print("❌ DASHVideoPlayer: Failed to create composition: \(error)")
      return nil
    }
  }

  /// 从PlayURLInfo中提取最佳视频和音频URL
  static func extractBestStreams(from playURLInfo: VideoPlayURLInfo) -> (
    videoURL: URL, audioURL: URL
  )? {
    extractBestStreams(from: playURLInfo, tier: .high)
  }

  static func extractBestStreams(
    from playURLInfo: VideoPlayURLInfo,
    tier: VideoPlaybackQualityTier
  ) -> (videoURL: URL, audioURL: URL)? {
    do {
      let selection = try DASHStreamSelection.select(from: playURLInfo, tier: tier)
      return (selection.video.primaryURL, selection.audio.primaryURL)
    } catch {
      print("❌ DASHVideoPlayer: Failed to extract best streams: \(error)")
      return nil
    }
  }

  /// 尝试使用备用音频流
  static func extractStreamsWithAlternativeAudio(
    from playURLInfo: VideoPlayURLInfo, skipAudioIds: Set<Int>
  ) -> (videoURL: URL, audioURL: URL)? {
    guard let dash = playURLInfo.dash,
      let videoStream = dash.video.first,
      let videoURL = URL(string: videoStream.baseUrl),
      let audioStreams = dash.audio
    else {
      return nil
    }

    // 找到未尝试过的音频流
    let availableStreams = audioStreams.filter { !skipAudioIds.contains($0.id) }
    guard let audioStream = availableStreams.sorted(by: { $0.id < $1.id }).first,
      let audioURL = URL(string: audioStream.baseUrl)
    else {
      return nil
    }

    print("🔄 DASHVideoPlayer: Trying alternative audio stream id: \(audioStream.id)")
    return (videoURL, audioURL)
  }
}
