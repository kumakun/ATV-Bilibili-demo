//
//  VideoDetailModels.swift
//  BilibiliLive
//
//  Created by GitHub Copilot on 2026/3/6.
//

import Foundation

// MARK: - Video Owner (已在ProfileModels.swift中定义，这里不重复)

// MARK: - Video Detail

struct VideoDetail: Codable, Hashable {
  let View: VideoInfo
  let Related: [VideoInfo]?
  let Card: UploaderCard

  struct VideoInfo: Codable, Hashable {
    let aid: Int
    let cid: Int
    let title: String
    let videos: Int?
    let pic: URL?
    let desc: String?
    let owner: VideoOwner
    let pages: [VideoPage]?
    let dynamic: String?
    let bvid: String?
    let duration: Int
    let pubdate: Int?
    let ugc_season: UgcSeason?
    let redirect_url: URL?
    let stat: VideoStat
    let ctime: Int?

    struct VideoStat: Codable, Hashable {
      let favorite: Int
      let coin: Int
      let like: Int
      let share: Int
      let danmaku: Int
      let view: Int
    }

    struct UgcSeason: Codable, Hashable {
      let id: Int
      let title: String
      let cover: URL
      let mid: Int
      let intro: String
      let attribute: Int
      let sections: [UgcSeasonDetail]

      struct UgcSeasonDetail: Codable, Hashable {
        let season_id: Int
        let id: Int
        let title: String
        let episodes: [UgcVideoInfo]
      }

      struct UgcVideoInfo: Codable, Hashable, Identifiable {
        let id: Int
        let aid: Int
        let cid: Int
        let arc: Arc
        let title: String

        struct Arc: Codable, Hashable {
          let pic: URL
          let ctime: Int
        }

        var picURL: URL? {
          arc.pic
        }
      }
    }

    // 格式化播放时长
    var durationString: String {
      let formatter = DateComponentsFormatter()
      if duration >= 3600 {
        formatter.allowedUnits = [.hour, .minute, .second]
      } else {
        formatter.allowedUnits = [.minute, .second]
      }
      formatter.zeroFormattingBehavior = .pad
      formatter.unitsStyle = .positional
      return formatter.string(from: TimeInterval(duration)) ?? ""
    }

    // 格式化发布日期
    var pubdateString: String? {
      guard let pubdate = pubdate else { return nil }
      let date = Date(timeIntervalSince1970: TimeInterval(pubdate))
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      return formatter.string(from: date)
    }
  }

  struct UploaderCard: Codable, Hashable {
    let following: Bool
    let follower: Int?
  }

  // 视频标题
  var title: String { View.title }

  // UP主名称
  var ownerName: String { View.owner.name }

  // 封面URL
  var picURL: URL? { View.pic }

  // UP主头像URL
  var avatarURL: URL? {
    guard let face = View.owner.face else { return nil }
    return URL(string: face)
  }
}

// MARK: - Video Page

struct VideoPage: Codable, Hashable, Identifiable {
  let cid: Int
  let page: Int
  let epid: Int?
  let from: String
  let part: String

  var id: Int { cid }

  // 分P标题（用于显示）
  var displayTitle: String {
    if part.isEmpty {
      return "P\(page)"
    }
    return part
  }
}

// MARK: - Stat Formatting Extensions

extension VideoDetail.VideoInfo.VideoStat {
  // 格式化数字（超过1万显示为"X.X万"）
  func formatCount(_ count: Int) -> String {
    if count >= 10000 {
      let formatted = Double(count) / 10000.0
      return String(format: "%.1f万", formatted)
    }
    return "\(count)"
  }

  var playCountString: String {
    formatCount(view)
  }

  var danmakuCountString: String {
    formatCount(danmaku)
  }

  var likeCountString: String {
    formatCount(like)
  }

  var coinCountString: String {
    formatCount(coin)
  }

  var favoriteCountString: String {
    formatCount(favorite)
  }

  var shareCountString: String {
    formatCount(share)
  }
}

// MARK: - Video Play URL Info

struct VideoPlayURLInfo: Codable, Hashable {
  let quality: Int
  let format: String?
  let timelength: Int?
  let dash: Dash?
  let durl: [Durl]?

  struct Durl: Codable, Hashable {
    let url: String
    let backupUrl: [String]?

    enum CodingKeys: String, CodingKey {
      case url
      case backupUrl = "backup_url"
    }

    var allUrls: [String] {
      var urls = [url]
      if let backupUrl {
        urls.append(contentsOf: backupUrl)
      }
      return urls
    }
  }

  struct Dash: Codable, Hashable {
    let duration: Int
    let video: [VideoStream]
    let audio: [AudioStream]?

    struct VideoStream: Codable, Hashable {
      let id: Int
      let baseUrl: String
      let backupUrl: [String]?
      let bandwidth: Int
      let codecid: Int
      let codecs: String?

      // 检查是否为HEVC编码
      var isHevc: Bool {
        guard let codecs = codecs else {
          // 如果没有codecs字段，通过codecid判断
          // codecid 7: AVC, 12: HEVC, 13: AV1
          return codecid == 12 || codecid == 13
        }
        return codecs.starts(with: "hev") || codecs.starts(with: "hvc")
          || codecs.starts(with: "dvh1")
      }

      // 获取所有可用URL（主URL + 备用URL）
      var allUrls: [String] {
        var urls = [baseUrl]
        if let backups = backupUrl {
          urls.append(contentsOf: backups)
        }
        return urls
      }
    }

    struct AudioStream: Codable, Hashable {
      let id: Int
      let baseUrl: String
      let backupUrl: [String]?
      let bandwidth: Int

      // 获取所有可用URL（主URL + 备用URL）
      var allUrls: [String] {
        var urls = [baseUrl]
        if let backups = backupUrl {
          urls.append(contentsOf: backups)
        }
        return urls
      }
    }
  }

  // 获取最佳视频流URL（用于后备）
  var bestVideoURL: URL? {
    if let videoStream = dash?.video.first {
      return URL(string: videoStream.baseUrl)
    }
    if let durl = durl?.first {
      return URL(string: durl.url)
    }
    return nil
  }

  var bestDirectPlayURL: URL? {
    guard let durl = durl?.first else { return nil }
    for urlString in durl.allUrls {
      if let url = URL(string: urlString) {
        return url
      }
    }
    return nil
  }
}

// MARK: - Player Info

struct PlayerInfo: Codable, Hashable {
  let last_play_time: Int
  let last_play_cid: Int?
  let is_upower_exclusive: Bool?

  var playTimeInSecond: Int {
    last_play_time
  }
}
