//
//  FollowModels.swift
//  BilibiliLive-iOS
//
//  Created on 2026/3/6.
//

import Foundation

// MARK: - DynamicFeedInfo

struct DynamicFeedInfo: Codable {
  let items: [DynamicFeedData]
  let offset: String
  let updateNum: Int
  let updateBaseline: String
  let hasMore: Bool

  enum CodingKeys: String, CodingKey {
    case items
    case offset
    case updateNum = "update_num"
    case updateBaseline = "update_baseline"
    case hasMore = "has_more"
  }

  var videoFeeds: [DynamicFeedData] {
    return items.filter { $0.aid != 0 || $0.modules.moduleDynamic.major?.pgc != nil }
  }
}

// MARK: - DynamicFeedData

struct DynamicFeedData: Codable, Identifiable, Hashable {
  let type: String
  let basic: Basic
  let modules: Modules
  let idStr: String

  enum CodingKeys: String, CodingKey {
    case type
    case basic
    case modules
    case idStr = "id_str"
  }

  // Identifiable
  var id: String { idStr }

  // Computed properties for video information
  var aid: Int {
    if let aidStr = modules.moduleDynamic.major?.archive?.aid {
      return Int(aidStr) ?? 0
    }
    return 0
  }

  var cid: Int { 0 }

  var title: String {
    modules.moduleDynamic.major?.archive?.title ?? modules.moduleDynamic.major?.pgc?.title ?? ""
  }

  var ownerName: String {
    modules.moduleAuthor.name
  }

  var pic: URL? {
    if let coverStr = modules.moduleDynamic.major?.archive?.cover {
      return URL(string: coverStr)
    }
    return modules.moduleDynamic.major?.pgc?.cover
  }

  var avatar: URL? {
    URL(string: modules.moduleAuthor.face)
  }

  var pubTime: String {
    modules.moduleAuthor.pubTime
  }

  var duration: String? {
    modules.moduleDynamic.major?.archive?.durationText
  }

  var playCountString: String {
    modules.moduleDynamic.major?.archive?.stat?.play ?? "-"
  }

  var danmakuCountString: String {
    modules.moduleDynamic.major?.archive?.stat?.danmaku ?? "-"
  }

  var epid: Int? {
    modules.moduleDynamic.major?.pgc?.epid
  }

  // MARK: - Nested Types

  struct Basic: Codable, Hashable {
    let commentIdStr: String
    let commentType: Int

    enum CodingKeys: String, CodingKey {
      case commentIdStr = "comment_id_str"
      case commentType = "comment_type"
    }
  }

  struct Modules: Codable, Hashable {
    let moduleAuthor: ModuleAuthor
    let moduleDynamic: ModuleDynamic

    enum CodingKeys: String, CodingKey {
      case moduleAuthor = "module_author"
      case moduleDynamic = "module_dynamic"
    }

    struct ModuleAuthor: Codable, Hashable {
      let face: String
      let mid: Int
      let name: String
      let pubTime: String

      enum CodingKeys: String, CodingKey {
        case face
        case mid
        case name
        case pubTime = "pub_time"
      }
    }

    struct ModuleDynamic: Codable, Hashable {
      let major: Major?

      struct Major: Codable, Hashable {
        let archive: Archive?
        let pgc: Pgc?

        struct Archive: Codable, Hashable {
          let aid: String?
          let cover: String?
          let desc: String?
          let title: String?
          let durationText: String?
          let stat: Stat?

          enum CodingKeys: String, CodingKey {
            case aid
            case cover
            case desc
            case title
            case durationText = "duration_text"
            case stat
          }

          struct Stat: Codable, Hashable {
            let danmaku: String?
            let play: String?
          }
        }

        struct Pgc: Codable, Hashable {
          let epid: Int
          let title: String?
          let cover: URL?
          let jumpUrl: URL?

          enum CodingKeys: String, CodingKey {
            case epid
            case title
            case cover
            case jumpUrl = "jump_url"
          }
        }
      }
    }
  }
}
