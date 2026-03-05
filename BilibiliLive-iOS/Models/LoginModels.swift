//
//  LoginModels.swift
//  BilibiliLive-iOS
//
//  Created by iOS Implementation on 2026/3/5.
//

import Foundation

// MARK: - Login Token

struct LoginToken: Codable, Equatable {
  let mid: Int
  let accessToken: String
  let refreshToken: String
  let expiresIn: Int
  var expireDate: Date?
}

// MARK: - User Profile

struct Profile: Codable, Equatable {
  let mid: Int
  var username: String
  var avatar: String
}

// MARK: - Account

struct Account: Codable, Equatable {
  var token: LoginToken
  var profile: Profile
  var cookies: [StoredCookie]
  var lastActiveAt: Date
}

// MARK: - Stored Cookie

struct StoredCookie: Codable, Equatable {
  let name: String
  let value: String
  let domain: String
  let path: String
  let expiresDate: Date?
  let isSecure: Bool
  let isHTTPOnly: Bool

  init(cookie: HTTPCookie) {
    name = cookie.name
    value = cookie.value
    domain = cookie.domain
    path = cookie.path
    expiresDate = cookie.expiresDate
    isSecure = cookie.isSecure
    isHTTPOnly = cookie.isHTTPOnly
  }

  func makeHTTPCookie() -> HTTPCookie? {
    var properties: [HTTPCookiePropertyKey: Any] = [
      .domain: domain,
      .name: name,
      .path: path,
      .value: value,
    ]
    if let expiresDate {
      properties[.expires] = expiresDate
    }
    if isSecure {
      properties[.secure] = "TRUE"
    }
    properties[HTTPCookiePropertyKey("HttpOnly")] = isHTTPOnly ? "TRUE" : "FALSE"
    return HTTPCookie(properties: properties)
  }
}
