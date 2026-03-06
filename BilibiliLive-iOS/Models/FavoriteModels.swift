//
//  FavoriteModels.swift
//  BilibiliLive-iOS
//
//  Created on 2026/3/6.
//

import Foundation

// MARK: - FavListDataIOS

struct FavListDataIOS: Codable, Identifiable, Hashable {
  let id: Int
  let title: String
  var mediaCount: Int?
  var isCreatedBySelf: Bool = false
  var mid: Int?

  enum CodingKeys: String, CodingKey {
    case id, title, mid
    case mediaCount = "media_count"
  }

  init(
    id: Int, title: String, mediaCount: Int? = nil, isCreatedBySelf: Bool = false, mid: Int? = nil
  ) {
    self.id = id
    self.title = title
    self.mediaCount = mediaCount
    self.isCreatedBySelf = isCreatedBySelf
    self.mid = mid
  }
}

// MARK: - FavDataIOS

struct FavDataIOS: Codable, Identifiable, Hashable {
  let id: Int
  let title: String
  let cover: String
  let intro: String?
  let duration: Int
  let upper: Upper?
  let cntInfo: CntInfo?
  let ogv: OGV?

  enum CodingKeys: String, CodingKey {
    case id, title, cover, intro, duration, upper, ogv
    case cntInfo = "cnt_info"
  }

  // MARK: - Nested Types

  struct Upper: Codable, Hashable {
    let mid: Int
    let name: String
    let face: String
  }

  struct CntInfo: Codable, Hashable {
    let play: Int
    let collect: Int
  }

  struct OGV: Codable, Hashable {
    let seasonId: Int

    enum CodingKeys: String, CodingKey {
      case seasonId = "season_id"
    }
  }

  // MARK: - Computed Properties

  /// 格式化时长为 "mm:ss" 或 "hh:mm:ss"
  var durationText: String {
    let hours = duration / 3600
    let minutes = (duration % 3600) / 60
    let seconds = duration % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%d:%02d", minutes, seconds)
    }
  }
}

// MARK: - Int Extension for Formatting

extension Int {
  /// 格式化播放数为易读格式（如 "1.2万"）
  func formattedPlayCount() -> String {
    if self >= 100_000_000 {
      return String(format: "%.1f亿", Double(self) / 100_000_000)
    } else if self >= 10_000 {
      return String(format: "%.1f万", Double(self) / 10_000)
    } else {
      return "\(self)"
    }
  }
}
