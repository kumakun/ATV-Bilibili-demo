//
//  ProfileModels.swift
//  BilibiliLive-iOS
//
//  Created by iOS Implementation on 2026/3/5.
//

import Foundation

// MARK: - User Profile

struct UserProfile: Decodable, Hashable {
  let mid: Int
  let username: String
  let avatar: String
  let sign: String

  enum CodingKeys: String, CodingKey {
    case mid
    case username = "uname"
    case name
    case avatar = "face"
    case sign
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let decodedUname = try container.decodeIfPresent(String.self, forKey: .username)
    let decodedName = try container.decodeIfPresent(String.self, forKey: .name)

    mid = try container.decodeIfPresent(Int.self, forKey: .mid) ?? 0
    username = decodedUname ?? decodedName ?? "未登录"
    avatar = try container.decodeIfPresent(String.self, forKey: .avatar) ?? ""
    sign = try container.decodeIfPresent(String.self, forKey: .sign) ?? "这是一段个人签名..."
  }
}

// MARK: - Following User

struct FollowingUser: Decodable, Hashable, Identifiable {
  let mid: Int
  let uname: String
  let face: String
  let sign: String

  enum CodingKeys: String, CodingKey {
    case mid
    case uname
    case face
    case sign
    case officialVerify = "official_verify"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    mid = try container.decodeIfPresent(Int.self, forKey: .mid) ?? 0
    uname = try container.decodeIfPresent(String.self, forKey: .uname) ?? "未知UP"
    face = try container.decodeIfPresent(String.self, forKey: .face) ?? ""
    sign = try container.decodeIfPresent(String.self, forKey: .sign) ?? ""
  }

  var id: Int { mid }

  var faceURL: URL? {
    URL(string: face)
  }
}

// MARK: - History Item

struct HistoryItem: Decodable, Hashable, Identifiable {
  let aid: Int
  let cid: Int?
  let title: String
  let pic: String
  let owner: VideoOwner
  let progress: Int?
  let duration: Int?
  let viewAt: Int

  private enum CodingKeys: String, CodingKey {
    case aid
    case id
    case cid
    case title
    case pic
    case cover
    case covers
    case owner
    case ownerName = "owner_name"
    case authorName = "author_name"
    case progress
    case duration
    case viewAt = "view_at"
    case history
  }

  private enum HistoryCodingKeys: String, CodingKey {
    case oid
    case cid
    case epid
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let history = try? container.nestedContainer(keyedBy: HistoryCodingKeys.self, forKey: .history)

    let decodedAid = try container.decodeIfPresent(Int.self, forKey: .aid)
    let decodedId = try container.decodeIfPresent(Int.self, forKey: .id)
    let decodedCid = try container.decodeIfPresent(Int.self, forKey: .cid)
    let decodedTitle = try container.decodeIfPresent(String.self, forKey: .title)
    let decodedPic = try container.decodeIfPresent(String.self, forKey: .pic)
    let decodedCover = try container.decodeIfPresent(String.self, forKey: .cover)
    let coverList = try container.decodeIfPresent([String].self, forKey: .covers)
    let decodedOwner = try container.decodeIfPresent(VideoOwner.self, forKey: .owner)
    let decodedAuthorName = try container.decodeIfPresent(String.self, forKey: .authorName)
    let decodedOwnerName = try container.decodeIfPresent(String.self, forKey: .ownerName)

    let historyOid: Int?
    let historyCid: Int?
    let historyEpid: Int?
    if let history {
      historyOid = try history.decodeIfPresent(Int.self, forKey: .oid)
      historyCid = try history.decodeIfPresent(Int.self, forKey: .cid)
      historyEpid = try history.decodeIfPresent(Int.self, forKey: .epid)
    } else {
      historyOid = nil
      historyCid = nil
      historyEpid = nil
    }

    let decodedViewAt = try container.decodeIfPresent(Int.self, forKey: .viewAt) ?? 0
    viewAt = decodedViewAt

    aid = decodedAid ?? decodedId ?? historyOid ?? decodedViewAt

    cid = decodedCid ?? historyCid ?? historyEpid

    title = decodedTitle ?? "未知标题"

    pic = decodedPic ?? decodedCover ?? coverList?.first ?? ""

    if let decodedOwner {
      owner = decodedOwner
    } else {
      let fallbackName = decodedAuthorName ?? decodedOwnerName ?? "未知UP主"
      owner = VideoOwner(mid: nil, name: fallbackName, face: nil)
    }

    progress = try container.decodeIfPresent(Int.self, forKey: .progress)
    duration = try container.decodeIfPresent(Int.self, forKey: .duration)
  }

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
