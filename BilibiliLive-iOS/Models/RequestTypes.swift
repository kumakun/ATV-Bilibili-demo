//
//  RequestTypes.swift
//  BilibiliLive-iOS
//
//  Created by iOS Implementation on 2026/3/5.
//

import Foundation

// MARK: - Request Error

enum RequestError: LocalizedError {
  case networkFail
  case statusFail(code: Int, message: String)
  case decodeFail(message: String)

  var errorDescription: String? {
    switch self {
    case .networkFail:
      return "网络连接失败，请检查网络设置"
    case .statusFail(let code, let message):
      if code == -101 {
        return "登录状态已失效，请重新登录"
      }
      return message.isEmpty ? "请求失败（错误码 \(code)）" : "\(message)（错误码 \(code)）"
    case .decodeFail(let message):
      return "数据解析失败：\(message)"
    }
  }
}

enum AppLog {
  static func error(_ error: Error, context: String) {
    Swift.print("❌ [\(context)] \(details(for: error))")
  }

  static func error(_ message: String, context: String) {
    Swift.print("❌ [\(context)] \(message)")
  }

  private static func details(for error: Error) -> String {
    guard let decodingError = error as? DecodingError else {
      return "\(error.localizedDescription) | \(String(reflecting: error))"
    }

    switch decodingError {
    case .keyNotFound(let key, let context):
      return "缺少字段 \(path(context.codingPath + [key]))：\(context.debugDescription)"
    case .typeMismatch(let type, let context):
      return "字段类型不匹配 \(path(context.codingPath))，期望 \(type)：\(context.debugDescription)"
    case .valueNotFound(let type, let context):
      return "字段值为空 \(path(context.codingPath))，期望 \(type)：\(context.debugDescription)"
    case .dataCorrupted(let context):
      return "数据损坏 \(path(context.codingPath))：\(context.debugDescription)"
    @unknown default:
      return String(reflecting: decodingError)
    }
  }

  private static func path(_ codingPath: [CodingKey]) -> String {
    let value = codingPath.map(\.stringValue).joined(separator: ".")
    return value.isEmpty ? "<root>" : value
  }
}

// MARK: - Cookie Handler

class CookieHandler {
  static let shared: CookieHandler = .init()

  let cookieStorage = HTTPCookieStorage.shared

  private init() {}

  func currentStoredCookies() -> [StoredCookie] {
    cookieStorage.cookies?.map(StoredCookie.init) ?? []
  }

  func replaceCookies(with cookies: [StoredCookie]) {
    removeCookie()
    for cookie in cookies {
      if let httpCookie = cookie.makeHTTPCookie() {
        cookieStorage.setCookie(httpCookie)
      }
    }
  }

  func removeCookie() {
    guard let cookies = cookieStorage.cookies else { return }
    for cookie in cookies {
      cookieStorage.deleteCookie(cookie)
    }
  }

  func csrf() -> String? {
    let cookies = cookieStorage.cookies(for: URL(string: "https://bilibili.com")!)
    return cookies?.first(where: { $0.name == "bili_jct" })?.value
  }
}
