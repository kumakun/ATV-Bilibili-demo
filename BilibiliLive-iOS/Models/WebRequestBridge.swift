//
//  WebRequestBridge.swift
//  BilibiliLive-iOS
//
//  Created by iOS Implementation on 2026/3/5.
//

import Alamofire
import Foundation
import SwiftyJSON

enum WebRequest {
  static func requestLoginInfo(
    accessKey: String? = nil, complete: @escaping (Result<JSON, RequestError>) -> Void
  ) {
    var parameters: [String: String] = [:]
    if let accessKey {
      parameters["access_key"] = accessKey
    }

    let url = "https://api.bilibili.com/x/space/myinfo"

    AF.request(url, parameters: parameters).responseData { response in
      switch response.result {
      case .success(let data):
        let json = JSON(data)
        let code = json["code"].intValue
        if code == 0 {
          complete(.success(json["data"]))
        } else {
          complete(.failure(.statusFail(code: code, message: json["message"].stringValue)))
        }
      case .failure(let error):
        print("Request failed: \(error)")
        complete(.failure(.networkFail))
      }
    }
  }

  // MARK: - Profile APIs

  static func requestUserInfo(mid: Int) async throws -> UserProfile {
    let url = "https://api.bilibili.com/x/space/acc/info"
    let parameters: [String: Any] = ["mid": mid]

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url, parameters: parameters).responseData { response in
        switch response.result {
        case .success(let data):
          let json = JSON(data)
          let code = json["code"].intValue
          if code == 0 {
            do {
              let data = try JSONDecoder().decode(UserProfile.self, from: json["data"].rawData())
              continuation.resume(returning: data)
            } catch {
              continuation.resume(
                throwing: RequestError.decodeFail(message: error.localizedDescription))
            }
          } else {
            continuation.resume(
              throwing: RequestError.statusFail(code: code, message: json["message"].stringValue))
          }
        case .failure:
          continuation.resume(throwing: RequestError.networkFail)
        }
      }
    }
  }

  static func requestFollowingUps(page: Int = 1) async throws -> [FollowingUser] {
    let url = "https://api.bilibili.com/x/relation/followings"
    guard let mid = AccountManagerIOS.shared.currentAccount?.profile.mid else {
      throw RequestError.statusFail(code: -1, message: "未登录")
    }
    let parameters: [String: Any] = [
      "vmid": mid,
      "order_type": "attention",
      "pn": page,
      "ps": 40,
    ]

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url, parameters: parameters).responseData { response in
        switch response.result {
        case .success(let data):
          let json = JSON(data)
          let code = json["code"].intValue
          if code == 0 {
            do {
              let list = try JSONDecoder().decode(
                [FollowingUser].self, from: json["data"]["list"].rawData())
              continuation.resume(returning: list)
            } catch {
              continuation.resume(
                throwing: RequestError.decodeFail(message: error.localizedDescription))
            }
          } else {
            continuation.resume(
              throwing: RequestError.statusFail(code: code, message: json["message"].stringValue))
          }
        case .failure:
          continuation.resume(throwing: RequestError.networkFail)
        }
      }
    }
  }

  static func requestHistory() async throws -> [HistoryItem] {
    let url = "https://api.bilibili.com/x/web-interface/history/cursor"

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url).responseData { response in
        switch response.result {
        case .success(let data):
          let json = JSON(data)
          let code = json["code"].intValue
          if code == 0 {
            do {
              let list = try JSONDecoder().decode(
                [HistoryItem].self, from: json["data"]["list"].rawData())
              continuation.resume(returning: list)
            } catch {
              print("Decode error: \(error)")
              continuation.resume(
                throwing: RequestError.decodeFail(message: error.localizedDescription))
            }
          } else {
            continuation.resume(
              throwing: RequestError.statusFail(code: code, message: json["message"].stringValue))
          }
        case .failure:
          continuation.resume(throwing: RequestError.networkFail)
        }
      }
    }
  }

  static func requestWatchLater() async throws -> [WatchLaterItem] {
    let url = "https://api.bilibili.com/x/v2/history/toview"

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url).responseData { response in
        switch response.result {
        case .success(let data):
          let json = JSON(data)
          let code = json["code"].intValue
          if code == 0 {
            do {
              let list = try JSONDecoder().decode(
                [WatchLaterItem].self, from: json["data"]["list"].rawData())
              continuation.resume(returning: list)
            } catch {
              continuation.resume(
                throwing: RequestError.decodeFail(message: error.localizedDescription))
            }
          } else {
            continuation.resume(
              throwing: RequestError.statusFail(code: code, message: json["message"].stringValue))
          }
        case .failure:
          continuation.resume(throwing: RequestError.networkFail)
        }
      }
    }
  }

  static func deleteWatchLater(aid: Int, csrf: String) async throws {
    let url = "https://api.bilibili.com/x/v2/history/toview/del"
    let parameters: [String: Any] = ["aid": aid, "csrf": csrf]

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url, method: .post, parameters: parameters).responseData { response in
        switch response.result {
        case .success(let data):
          let json = JSON(data)
          let code = json["code"].intValue
          if code == 0 {
            continuation.resume()
          } else {
            continuation.resume(
              throwing: RequestError.statusFail(code: code, message: json["message"].stringValue))
          }
        case .failure:
          continuation.resume(throwing: RequestError.networkFail)
        }
      }
    }
  }

  static func requestFollowBangumi(type: Int, page: Int = 1) async throws -> [BangumiItem] {
    let url = "https://api.bilibili.com/x/space/bangumi/follow/list"
    // Need to get vmid from current account
    guard let mid = AccountManagerIOS.shared.currentAccount?.profile.mid else {
      throw RequestError.statusFail(code: -1, message: "Not logged in")
    }
    let parameters: [String: Any] = ["vmid": mid, "type": type, "pn": page, "ps": 24]

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url, parameters: parameters).responseData { response in
        switch response.result {
        case .success(let data):
          let json = JSON(data)
          let code = json["code"].intValue
          if code == 0 {
            do {
              let list = try JSONDecoder().decode(
                [BangumiItem].self, from: json["data"]["list"].rawData())
              continuation.resume(returning: list)
            } catch {
              continuation.resume(
                throwing: RequestError.decodeFail(message: error.localizedDescription))
            }
          } else {
            continuation.resume(
              throwing: RequestError.statusFail(code: code, message: json["message"].stringValue))
          }
        case .failure:
          continuation.resume(throwing: RequestError.networkFail)
        }
      }
    }
  }

  static func requestWeeklyWatchList() async throws -> [WeeklyList] {
    let url = "https://api.bilibili.com/x/web-interface/popular/series/list"

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url).responseData { response in
        switch response.result {
        case .success(let data):
          let json = JSON(data)
          let code = json["code"].intValue
          if code == 0 {
            do {
              let list = try JSONDecoder().decode(
                [WeeklyList].self, from: json["data"]["list"].rawData())
              continuation.resume(returning: list)
            } catch {
              continuation.resume(
                throwing: RequestError.decodeFail(message: error.localizedDescription))
            }
          } else {
            continuation.resume(
              throwing: RequestError.statusFail(code: code, message: json["message"].stringValue))
          }
        case .failure:
          continuation.resume(throwing: RequestError.networkFail)
        }
      }
    }
  }

  static func requestWeeklyWatch(wid: Int) async throws -> [WeeklyVideo] {
    let url = "https://api.bilibili.com/x/web-interface/popular/series/one"
    let parameters: [String: Any] = ["number": wid]

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url, parameters: parameters).responseData { response in
        switch response.result {
        case .success(let data):
          let json = JSON(data)
          let code = json["code"].intValue
          if code == 0 {
            do {
              let list = try JSONDecoder().decode(
                [WeeklyVideo].self, from: json["data"]["list"].rawData())
              continuation.resume(returning: list)
            } catch {
              continuation.resume(
                throwing: RequestError.decodeFail(message: error.localizedDescription))
            }
          } else {
            continuation.resume(
              throwing: RequestError.statusFail(code: code, message: json["message"].stringValue))
          }
        case .failure:
          continuation.resume(throwing: RequestError.networkFail)
        }
      }
    }
  }

  static func logout() async throws {
    let url = "https://passport.bilibili.com/login/exit/v2"
    let csrf = CookieHandler.shared.csrf()
    let parameters: [String: Any] = ["biliCSRF": csrf]

    let response = await AF.request(url, method: .post, parameters: parameters).serializingData()
      .response

    if let error = response.error {
      throw error
    }

    CookieHandler.shared.removeCookie()
    try await ApiRequest.logout()  // Revoke the token
    AccountManagerIOS.shared.removeAllAccounts()  // Clear local account data
  }

  // MARK: - Favorite APIs

  static func requestFavVideosList() async throws -> [FavListDataIOS] {
    let url = "https://api.bilibili.com/x/v3/fav/folder/created/list-all"
    guard let mid = AccountManagerIOS.shared.currentAccount?.profile.mid else {
      throw RequestError.statusFail(code: -1, message: "未登录")
    }
    let parameters: [String: Any] = ["up_mid": mid]

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url, parameters: parameters).responseData { response in
        switch response.result {
        case .success(let data):
          let json = JSON(data)
          let code = json["code"].intValue
          if code == 0 {
            do {
              var list = try JSONDecoder().decode(
                [FavListDataIOS].self, from: json["data"]["list"].rawData())
              // 标记为用户自建收藏夹
              for i in 0..<list.count {
                list[i].isCreatedBySelf = true
              }
              continuation.resume(returning: list)
            } catch {
              continuation.resume(
                throwing: RequestError.decodeFail(message: error.localizedDescription))
            }
          } else {
            continuation.resume(
              throwing: RequestError.statusFail(code: code, message: json["message"].stringValue))
          }
        case .failure:
          continuation.resume(throwing: RequestError.networkFail)
        }
      }
    }
  }

  static func requestFavVideos(mediaId: String, page: Int) async throws -> [FavDataIOS] {
    let url = "https://api.bilibili.com/x/v3/fav/resource/list"
    let parameters: [String: Any] = ["media_id": mediaId, "ps": 20, "pn": page, "platform": "web"]

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url, parameters: parameters).responseData { response in
        switch response.result {
        case .success(let data):
          let json = JSON(data)
          let code = json["code"].intValue
          if code == 0 {
            do {
              let medias = json["data"]["medias"]
              if medias == JSON.null {
                continuation.resume(returning: [])
              } else {
                let list = try JSONDecoder().decode([FavDataIOS].self, from: medias.rawData())
                continuation.resume(returning: list)
              }
            } catch {
              continuation.resume(
                throwing: RequestError.decodeFail(message: error.localizedDescription))
            }
          } else {
            continuation.resume(
              throwing: RequestError.statusFail(code: code, message: json["message"].stringValue))
          }
        case .failure:
          continuation.resume(throwing: RequestError.networkFail)
        }
      }
    }
  }

  static func requestFavFolderCollectedList() async throws -> [FavListDataIOS] {
    let url = "https://api.bilibili.com/x/v3/fav/folder/collected/list"
    guard let mid = AccountManagerIOS.shared.currentAccount?.profile.mid else {
      throw RequestError.statusFail(code: -1, message: "未登录")
    }
    let parameters: [String: Any] = ["up_mid": mid, "pn": 1, "ps": 100, "platform": "web"]

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url, parameters: parameters).responseData { response in
        switch response.result {
        case .success(let data):
          let json = JSON(data)
          let code = json["code"].intValue
          if code == 0 {
            do {
              let list = try JSONDecoder().decode(
                [FavListDataIOS].self, from: json["data"]["list"].rawData())
              continuation.resume(returning: list)
            } catch {
              continuation.resume(
                throwing: RequestError.decodeFail(message: error.localizedDescription))
            }
          } else {
            continuation.resume(
              throwing: RequestError.statusFail(code: code, message: json["message"].stringValue))
          }
        case .failure:
          continuation.resume(throwing: RequestError.networkFail)
        }
      }
    }
  }

  static func requestFavSeason(seasonId: String, page: Int) async throws -> [FavDataIOS] {
    let url = "https://api.bilibili.com/x/v3/fav/resource/list"
    let parameters: [String: Any] = [
      "season_id": seasonId, "ps": 20, "pn": page, "platform": "web",
    ]

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url, parameters: parameters).responseData { response in
        switch response.result {
        case .success(let data):
          let json = JSON(data)
          let code = json["code"].intValue
          if code == 0 {
            do {
              let medias = json["data"]["medias"]
              if medias == JSON.null {
                continuation.resume(returning: [])
              } else {
                let list = try JSONDecoder().decode([FavDataIOS].self, from: medias.rawData())
                continuation.resume(returning: list)
              }
            } catch {
              continuation.resume(
                throwing: RequestError.decodeFail(message: error.localizedDescription))
            }
          } else {
            continuation.resume(
              throwing: RequestError.statusFail(code: code, message: json["message"].stringValue))
          }
        case .failure:
          continuation.resume(throwing: RequestError.networkFail)
        }
      }
    }
  }

  // MARK: - Follow Feed APIs

  static func requestFollowsFeed(offset: String, page: Int) async throws -> DynamicFeedInfo {
    let url = "https://api.bilibili.com/x/polymer/web-dynamic/v1/feed/all"
    var parameters: [String: Any] = [
      "type": "all",
      "timezone_offset": "-480",
      "page": page,
    ]

    if let offsetNum = Int(offset), offsetNum > 0 {
      parameters["offset"] = offsetNum
    }

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url, parameters: parameters).responseData { response in
        switch response.result {
        case .success(let data):
          let json = JSON(data)
          let code = json["code"].intValue
          if code == 0 {
            do {
              let feedInfo = try JSONDecoder().decode(
                DynamicFeedInfo.self, from: json["data"].rawData())

              // 如果没有视频内容且还有更多数据，递归请求下一页
              if feedInfo.videoFeeds.isEmpty && feedInfo.hasMore {
                Task {
                  do {
                    let nextFeed = try await requestFollowsFeed(
                      offset: feedInfo.offset, page: page)
                    continuation.resume(returning: nextFeed)
                  } catch {
                    continuation.resume(throwing: error)
                  }
                }
              } else {
                continuation.resume(returning: feedInfo)
              }
            } catch {
              continuation.resume(
                throwing: RequestError.decodeFail(message: error.localizedDescription))
            }
          } else {
            continuation.resume(
              throwing: RequestError.statusFail(code: code, message: json["message"].stringValue))
          }
        case .failure:
          continuation.resume(throwing: RequestError.networkFail)
        }
      }
    }
  }

  // MARK: - Video Detail APIs

  static func requestVideoDetail(aid: Int) async throws -> VideoDetail {
    let url = "https://api.bilibili.com/x/web-interface/view/detail"
    let parameters: [String: Any] = ["aid": aid]

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url, parameters: parameters).responseData { response in
        switch response.result {
        case .success(let data):
          let json = JSON(data)
          let code = json["code"].intValue
          if code == 0 {
            do {
              let videoDetail = try JSONDecoder().decode(
                VideoDetail.self, from: json["data"].rawData())
              continuation.resume(returning: videoDetail)
            } catch {
              print("Decode error: \(error)")
              continuation.resume(
                throwing: RequestError.decodeFail(message: error.localizedDescription))
            }
          } else {
            continuation.resume(
              throwing: RequestError.statusFail(code: code, message: json["message"].stringValue))
          }
        case .failure:
          continuation.resume(throwing: RequestError.networkFail)
        }
      }
    }
  }

  static func requestPlayUrl(aid: Int, cid: Int) async throws -> VideoPlayURLInfo {
    let url = "https://api.bilibili.com/x/player/playurl"
    // 请求最高画质 (fnval=976 支持DASH/杜比视界/8K, qn=127 请求8K)
    let parameters: [String: Any] = [
      "avid": aid,
      "cid": cid,
      "qn": 127,  // 最高画质
      "type": "",
      "fnver": 0,
      "fnval": 976,  // DASH格式
      "otype": "json",
    ]

    print("📡 WebRequestBridge: Requesting play URL with aid=\(aid), cid=\(cid)")

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url, parameters: parameters).responseData { response in
        switch response.result {
        case .success(let data):
          let json = JSON(data)
          let code = json["code"].intValue
          print("📡 WebRequestBridge: Response code=\(code)")
          if code == 0 {
            do {
              let playURLInfo = try JSONDecoder().decode(
                VideoPlayURLInfo.self, from: json["data"].rawData())
              print("✅ WebRequestBridge: Decoded successfully")
              print("   Quality: \(playURLInfo.quality)")
              print("   Video streams: \(playURLInfo.dash?.video.count ?? 0)")
              print("   Audio streams: \(playURLInfo.dash?.audio?.count ?? 0)")
              continuation.resume(returning: playURLInfo)
            } catch {
              print("❌ WebRequestBridge: Decode error: \(error)")
              continuation.resume(
                throwing: RequestError.decodeFail(message: error.localizedDescription))
            }
          } else {
            print("❌ WebRequestBridge: API error code \(code): \(json["message"].stringValue)")
            continuation.resume(
              throwing: RequestError.statusFail(code: code, message: json["message"].stringValue))
          }
        case .failure:
          print("❌ WebRequestBridge: Network failure")
          continuation.resume(throwing: RequestError.networkFail)
        }
      }
    }
  }

  static func requestDirectPlayUrl(aid: Int, cid: Int) async throws -> VideoPlayURLInfo {
    let url = "https://api.bilibili.com/x/player/playurl"
    let parameters: [String: Any] = [
      "avid": aid,
      "cid": cid,
      "qn": 64,
      "type": "",
      "fnver": 0,
      "fnval": 0,
      "otype": "json",
      "fourk": 0,
    ]

    print("📡 WebRequestBridge: Requesting direct play URL with aid=\(aid), cid=\(cid)")

    return try await withCheckedThrowingContinuation { continuation in
      AF.request(url, parameters: parameters).responseData { response in
        switch response.result {
        case .success(let data):
          let json = JSON(data)
          let code = json["code"].intValue
          print("📡 WebRequestBridge: Direct play response code=\(code)")
          if code == 0 {
            do {
              let playURLInfo = try JSONDecoder().decode(
                VideoPlayURLInfo.self, from: json["data"].rawData())
              print("✅ WebRequestBridge: Direct play URL decoded successfully")
              print("   Format: \(playURLInfo.format ?? "unknown")")
              print("   Durl count: \(playURLInfo.durl?.count ?? 0)")
              continuation.resume(returning: playURLInfo)
            } catch {
              print("❌ WebRequestBridge: Direct play decode error: \(error)")
              continuation.resume(
                throwing: RequestError.decodeFail(message: error.localizedDescription))
            }
          } else {
            print(
              "❌ WebRequestBridge: Direct play API error code \(code): \(json["message"].stringValue)"
            )
            continuation.resume(
              throwing: RequestError.statusFail(code: code, message: json["message"].stringValue))
          }
        case .failure:
          print("❌ WebRequestBridge: Direct play network failure")
          continuation.resume(throwing: RequestError.networkFail)
        }
      }
    }
  }
}
