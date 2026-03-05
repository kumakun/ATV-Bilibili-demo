//
//  ApiRequestBridge.swift
//  BilibiliLive-iOS
//
//  Created by iOS Implementation on 2026/3/5.
//

import Alamofire
import CryptoKit
import Foundation
import SwiftyJSON

enum ApiRequest {
  static let appkey = "5ae412b53418aac5"
  static let appsec = "5b9cf6c9786efd204dcf0c1ce2d08436"

  enum EndPoint {
    static let loginQR = "https://passport.bilibili.com/x/passport-tv-login/qrcode/auth_code"
    static let verifyQR = "https://passport.bilibili.com/x/passport-tv-login/qrcode/poll"
  }

  enum LoginState {
    case success(token: LoginToken, cookies: [HTTPCookie])
    case fail
    case expire
    case waiting
  }

  static func sign(for param: [String: Any]) -> [String: Any] {
    var newParam = param
    newParam["appkey"] = appkey
    newParam["ts"] = "\(Int(Date().timeIntervalSince1970))"
    newParam["local_id"] = "0"
    newParam["mobi_app"] = "iphone"
    newParam["device"] = "pad"
    newParam["device_name"] = "iPad"
    var rawParam =
      newParam
      .sorted(by: { $0.0 < $1.0 })
      .map({ "\($0.key)=\($0.value)" })
      .joined(separator: "&")
    rawParam.append(appsec)

    let md5 = Insecure.MD5
      .hash(data: rawParam.data(using: .utf8)!)
      .map { String(format: "%02hhx", $0) }
      .joined()
    newParam["sign"] = md5
    return newParam
  }

  static func requestLoginQR(handler: ((String, String) -> Void)? = nil) {
    struct Resp: Codable {
      let authCode: String
      let url: String
    }
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let parameters = sign(for: [:])

    AF.request(
      EndPoint.loginQR, method: .post, parameters: parameters, encoding: URLEncoding.default
    )
    .responseData { response in
      switch response.result {
      case .success(let data):
        let json = JSON(data)
        if json["code"].intValue == 0 {
          do {
            let resp = try decoder.decode(Resp.self, from: json["data"].rawData())
            handler?(resp.authCode, resp.url)
          } catch {
            print("Decode error: \(error)")
          }
        }
      case .failure(let error):
        print("Request error: \(error)")
      }
    }
  }

  struct LoginResp: Codable {
    struct CookieInfo: Codable {
      let domains: [String]
      let cookies: [Cookie]
      func toCookies() -> [HTTPCookie] {
        domains.map { domain in
          cookies.compactMap { $0.toCookie(domain: domain) }
        }.reduce([], +)
      }
    }

    struct Cookie: Codable {
      let name: String
      let value: String
      let httpOnly: Int
      let expires: Int

      func toCookie(domain: String) -> HTTPCookie? {
        HTTPCookie(properties: [
          .domain: domain,
          .name: name,
          .value: value,
          .expires: Date(timeIntervalSince1970: TimeInterval(expires)),
          HTTPCookiePropertyKey("HttpOnly"): httpOnly,
          .path: "",
        ])
      }
    }

    var tokenInfo: LoginToken
    let cookieInfo: CookieInfo
  }

  static func verifyLoginQR(code: String, handler: ((LoginState) -> Void)? = nil) {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let parameters = sign(for: ["auth_code": code])

    AF.request(
      EndPoint.verifyQR, method: .post, parameters: parameters, encoding: URLEncoding.default
    )
    .responseData { response in
      switch response.result {
      case .success(var data):
        let json = JSON(data)
        let code = json["code"].intValue

        if code == 0 {
          do {
            var resp = try decoder.decode(LoginResp.self, from: json["data"].rawData())
            resp.tokenInfo.expireDate = Date().addingTimeInterval(
              TimeInterval(resp.tokenInfo.expiresIn))
            let cookies = resp.cookieInfo.toCookies()
            CookieHandler.shared.replaceCookies(with: cookies.map(StoredCookie.init))
            handler?(.success(token: resp.tokenInfo, cookies: cookies))
          } catch {
            print("Decode error: \(error)")
            handler?(.fail)
          }
        } else {
          switch code {
          case 86038: handler?(.expire)
          case 86039: handler?(.waiting)
          default: handler?(.fail)
          }
        }
      case .failure(let error):
        print("Request error: \(error)")
        handler?(.fail)
      }
    }
  }

  // MARK: - Profile APIs

  static func getUserProfile(mid: Int) async throws -> UserProfile {
    try await WebRequest.requestUserInfo(mid: mid)
  }

  static func requestFollowingUps(page: Int = 1) async throws -> [FollowingUser] {
    try await WebRequest.requestFollowingUps(page: page)
  }

  static func requestHistory() async throws -> [HistoryItem] {
    try await WebRequest.requestHistory()
  }

  static func requestToView() async throws -> [WatchLaterItem] {
    try await WebRequest.requestWatchLater()
  }

  static func requestFollowBangumi(type: Int, page: Int = 1) async throws -> [BangumiItem] {
    try await WebRequest.requestFollowBangumi(type: type, page: page)
  }

  static func requestWeeklyWatchList() async throws -> [WeeklyList] {
    try await WebRequest.requestWeeklyWatchList()
  }

  static func requestWeeklyWatch(wid: Int) async throws -> [WeeklyVideo] {
    try await WebRequest.requestWeeklyWatch(wid: wid)
  }

  static func deleteToView(aid: Int, csrf: String) async throws {
    try await WebRequest.deleteWatchLater(aid: aid, csrf: csrf)
  }

  static func logout() async throws {
    guard let token = AccountManagerIOS.shared.currentAccount?.token else { return }
    let parameters = sign(for: ["access_token": token.accessToken])
    let url = "https://passport.bilibili.com/api/v2/oauth2/revoke"

    let response = await AF.request(url, method: .post, parameters: parameters).serializingData()
      .response

    if let error = response.error {
      throw error
    }
  }
}
