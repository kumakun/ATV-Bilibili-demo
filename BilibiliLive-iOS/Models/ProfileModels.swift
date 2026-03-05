//
//  ProfileModels.swift
//  BilibiliLive-iOS
//
//  Created by iOS Implementation on 2026/3/5.
//

import Foundation

// MARK: - User Profile

struct UserProfile: Codable, Hashable {
  let mid: Int
  let username: String
  let avatar: String
  let sign: String

  enum CodingKeys: String, CodingKey {
    case mid
    case username = "uname"
    case avatar = "face"
    case sign
  }
}

// MARK: - Following User

struct FollowingUser: Codable, Hashable, Identifiable {
  let mid: Int
  let uname: String
  let face: String
  let sign: String

  var id: Int { mid }

  var faceURL: URL? {
    URL(string: face)
  }
}

// MARK: - History Item

struct HistoryItem: Codable, Hashable, Identifiable {
  let aid: Int
  let cid: Int?
  let title: String
  let pic: String
  let owner: VideoOwner
  let progress: Int?
  let duration: Int?
  let viewAt: Int

  var id: Int { aid }

  var picURL: URL? {
    URL(string: pic)
  }

  var ownerName: String {
    owner.name
  }

  var viewAtDate: Date {
    Date(timeIntervalSince1970: TimeInterval(viewAt))
  }
}

struct VideoOwner: Codable, Hashable {
  let mid: Int?
  let name: String
  let face: String?
}

// MARK: - Watch Later Item

struct WatchLaterItem: Codable, Hashable, Identifiable {
  let aid: Int
  let cid: Int
  let title: String
  let pic: String
  let owner: VideoOwner
  let duration: Int
  let pubdate: Int
  let stat: VideoStat?

  var id: Int { aid }

  var picURL: URL? {
    URL(string: pic)
  }

  var ownerName: String {
    owner.name
  }

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
}

struct VideoStat: Codable, Hashable {
  let view: Int
  let danmaku: Int
}

// MARK: - Bangumi Item

struct BangumiItem: Codable, Hashable, Identifiable {
  let seasonId: Int
  let mediaId: Int
  let title: String
  let cover: String
  let progress: String?
  let newEp: NewEpisode?

  var id: Int { seasonId }

  enum CodingKeys: String, CodingKey {
    case seasonId = "season_id"
    case mediaId = "media_id"
    case title
    case cover
    case progress
    case newEp = "new_ep"
  }

  var coverURL: URL? {
    if let newCover = newEp?.cover {
      return URL(string: newCover)
    }
    return URL(string: cover)
  }

  var isUpdatedToday: Bool {
    guard let pubTime = newEp?.pubTime else { return false }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    if let date = formatter.date(from: pubTime) {
      return Calendar.current.isDateInToday(date)
    }
    return false
  }
}

struct NewEpisode: Codable, Hashable {
  let indexShow: String?
  let cover: String?
  let pubTime: String?

  enum CodingKeys: String, CodingKey {
    case indexShow = "index_show"
    case cover
    case pubTime = "pub_time"
  }
}

// MARK: - Weekly Watch

struct WeeklyList: Codable, Hashable, Identifiable {
  let number: Int
  let subject: String
  let name: String

  var id: Int { number }
}

struct WeeklyVideo: Codable, Hashable, Identifiable {
  let aid: Int
  let title: String
  let pic: String
  let owner: VideoOwner
  let stat: VideoStat?

  var id: Int { aid }

  var picURL: URL? {
    URL(string: pic)
  }
}

// MARK: - Profile Route

enum ProfileRoute: Hashable {
  case followUps
  case followBangumi
  case watchHistory
  case watchLater
  case weeklyWatch
  case videoDetail(aid: Int)
  case accountSwitcher
}
