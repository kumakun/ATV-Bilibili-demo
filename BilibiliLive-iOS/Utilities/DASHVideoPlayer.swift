//
//  DASHVideoPlayer.swift
//  BilibiliLive-iOS
//
//  Created by GitHub Copilot on 2026/3/6.
//

import AVFoundation
import Foundation

/// DASH视频播放器管理器，用于处理B站的DASH格式视频（音视频分离）
class DASHVideoPlayer {

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
    guard let dash = playURLInfo.dash else {
      print("❌ DASHVideoPlayer: No DASH info found")
      return nil
    }

    // 获取视频流（优先选择AVC/H.264，避免HEVC兼容性问题）
    var videoStreams = dash.video

    print("🎬 DASHVideoPlayer: Available video streams:")
    for stream in videoStreams.prefix(3) {
      let codecsStr = stream.codecs ?? "unknown"
      print(
        "   ID: \(stream.id), codecid: \(stream.codecid), codecs: \(codecsStr), bandwidth: \(stream.bandwidth)"
      )
    }

    // 优先选择AVC编码（H.264）以获得最佳兼容性
    // 按画质分组，每个画质优先选择AVC
    let qualityGroups = Dictionary(grouping: videoStreams, by: { $0.id })
    var selectedStreams: [VideoPlayURLInfo.Dash.VideoStream] = []

    for (_, streams) in qualityGroups {
      // 先找AVC编码
      if let avcStream = streams.first(where: { !$0.isHevc }) {
        selectedStreams.append(avcStream)
      } else if let hevcStream = streams.first {
        // 没有AVC才用HEVC
        selectedStreams.append(hevcStream)
      }
    }

    // 按画质排序，选择最高画质
    videoStreams = selectedStreams.sorted { $0.id > $1.id }

    guard let videoStream = videoStreams.first,
      let videoURL = URL(string: videoStream.baseUrl)
    else {
      print("❌ DASHVideoPlayer: No video stream found")
      return nil
    }

    // 尝试获取音频流
    guard let audioStreams = dash.audio, !audioStreams.isEmpty else {
      print("❌ DASHVideoPlayer: No audio stream found")
      return nil
    }

    print("🎵 DASHVideoPlayer: Available audio streams:")
    for stream in audioStreams {
      print("   ID: \(stream.id), bandwidth: \(stream.bandwidth)")
    }

    // iOS原生支持的音频格式优先级：
    // 30216: AAC-LC 64kbps (最佳兼容性)
    // 30232: AAC-LC 132kbps
    // 30280: AAC-HE (部分设备可能不支持)

    // 优先选择30216或30232 (标准AAC格式)
    let preferredIds = [30216, 30232, 30251]
    let selectedStream =
      preferredIds.compactMap { preferredId in
        audioStreams.first { $0.id == preferredId }
      }.first ?? audioStreams.sorted { $0.id < $1.id }.first

    guard let audioStream = selectedStream,
      let audioURL = URL(string: audioStream.baseUrl)
    else {
      print("❌ DASHVideoPlayer: Failed to create audio URL")
      return nil
    }

    print("✅ DASHVideoPlayer: Extracted streams")
    let codecsStr = videoStream.codecs ?? "unknown"
    print(
      "   Video quality: \(videoStream.id), codecid: \(videoStream.codecid), codecs: \(codecsStr) \(videoStream.isHevc ? "(HEVC)" : "(AVC)")"
    )
    print("   Audio id: \(audioStream.id) (from \(audioStreams.count) streams)")

    return (videoURL, audioURL)
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
