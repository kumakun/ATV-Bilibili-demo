//
//  RequestTypes.swift
//  BilibiliLive-iOS
//
//  Created by iOS Implementation on 2026/3/5.
//

import Foundation

// MARK: - Request Error

enum RequestError: Error {
  case networkFail
  case statusFail(code: Int, message: String)
  case decodeFail(message: String)
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
}
