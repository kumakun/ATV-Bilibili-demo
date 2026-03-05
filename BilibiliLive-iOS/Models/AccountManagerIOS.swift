//
//  AccountManagerIOS.swift
//  BilibiliLive-iOS
//
//  Created by iOS Implementation on 2026/3/5.
//

import Foundation
import SwiftyJSON

@MainActor
@Observable
final class AccountManagerIOS {
  // MARK: - Nested Types
  
  struct Profile: Codable, Equatable {
    let mid: Int
    var username: String
    var avatar: String
  }
  
  struct Account: Codable, Equatable {
    var token: LoginToken
    var profile: Profile
    var cookies: [StoredCookie]
    var lastActiveAt: Date
  }
  
  // MARK: - Singleton

  static let shared = AccountManagerIOS()

  // MARK: - Published Properties

  var isLoggedIn: Bool = false
  var currentAccount: Account?
  var accounts: [Account] = []

  // MARK: - Private Properties

  private let accountsKey = "ios.accounts"
  private let activeKey = "ios.accounts.active"
  private let storage = UserDefaults.standard
  private var activeMID: Int?

  // MARK: - Initialization

  private init() {
    loadFromStorage()
  }

  // MARK: - Bootstrap

  func bootstrap() {
    // Auto-activate the most recently used account if no active account
    if currentAccount == nil,
      let first = accounts.sorted(by: { $0.lastActiveAt > $1.lastActiveAt }).first
    {
      activeMID = first.profile.mid
      persistActiveMID()
    }
    applyActiveAccountCookies()
    updateLoginState()
  }

  // MARK: - Account Registration

  func registerAccount(
    token: LoginToken, cookies: [HTTPCookie], completion: @escaping (Account) -> Void
  ) {
    let storedCookies = cookies.map(StoredCookie.init)

    // Fetch user profile
    fetchProfile(using: token) { [weak self] result in
      Task { @MainActor in
        guard let self else { return }

        let profile: Profile
        switch result {
        case .success(let json):
          profile = Profile(
            mid: json["mid"].intValue,
            username: json["uname"].stringValue,
            avatar: json["face"].stringValue
          )
        case .failure:
          // Use default profile if API fails
          profile = Profile(
            mid: token.mid,
            username: "UID \(token.mid)",
            avatar: ""
          )
        }

        var newAccount = Account(
          token: token,
          profile: profile,
          cookies: storedCookies,
          lastActiveAt: Date()
        )

        self.upsert(account: newAccount)
        self.setActiveAccount(mid: newAccount.profile.mid, applyingCookies: false)
        self.updateAccount(mid: newAccount.profile.mid) { account in
          account.cookies = storedCookies
          account.lastActiveAt = Date()
          newAccount = account
        }
        self.applyActiveAccountCookies()
        self.persistAll()
        self.updateLoginState()

        completion(newAccount)
      }
    }
  }

  // MARK: - Active Account Management

  func setActiveAccount(mid: Int, applyingCookies: Bool = true) {
    guard accounts.contains(where: { $0.profile.mid == mid }) else { return }
    activeMID = mid
    persistActiveMID()
    updateAccount(mid: mid) { account in
      account.lastActiveAt = Date()
    }
    if applyingCookies {
      applyActiveAccountCookies()
    }
    persistAll()
    updateLoginState()
  }

  // MARK: - Account Updates

  func updateActiveProfile(username: String, avatar: String) {
    guard let mid = currentAccount?.profile.mid else { return }
    updateAccount(mid: mid) { account in
      account.profile.username = username
      account.profile.avatar = avatar
    }
    persistAll()
    updateLoginState()
  }

  func refreshActiveAccountProfile() {
    fetchProfile { [weak self] result in
      Task { @MainActor in
        guard let self else { return }
        switch result {
        case .success(let json):
          self.updateActiveProfile(
            username: json["uname"].stringValue,
            avatar: json["face"].stringValue
          )
        case .failure:
          break
        }
      }
    }
  }

  // MARK: - Account Removal

  @discardableResult
  func removeAccount(_ account: Account) -> Bool {
    accounts.removeAll(where: { $0.profile.mid == account.profile.mid })
    persistAccounts()

    let removedActive = activeMID == account.profile.mid
    if removedActive {
      activeMID = nil
      persistActiveMID()
      if let next = accounts.sorted(by: { $0.lastActiveAt > $1.lastActiveAt }).first {
        setActiveAccount(mid: next.profile.mid)
      } else {
        CookieHandler.shared.removeCookie()
        updateLoginState()
      }
    } else {
      updateLoginState()
    }

    return !accounts.isEmpty
  }

  func removeAllAccounts() {
    accounts.removeAll()
    persistAccounts()
    activeMID = nil
    persistActiveMID()
    CookieHandler.shared.removeCookie()
    updateLoginState()
  }

  // MARK: - Authentication Failure Handling

  func handleAuthenticationFailure() {
    guard let account = currentAccount else { return }
    _ = removeAccount(account)
  }

  // MARK: - Private Helpers

  private func fetchProfile(
    using token: LoginToken? = nil, completion: @escaping (Result<JSON, RequestError>) -> Void
  ) {
    WebRequest.requestLoginInfo(accessKey: token?.accessToken, complete: completion)
  }

  private func applyActiveAccountCookies() {
    guard let cookies = currentAccount?.cookies else { return }
    CookieHandler.shared.replaceCookies(with: cookies)
  }

  private func updateLoginState() {
    if let activeMID {
      currentAccount = accounts.first(where: { $0.profile.mid == activeMID })
      isLoggedIn = currentAccount != nil
      print("✅ AccountManagerIOS: Login state updated - isLoggedIn: \(isLoggedIn)")
    } else {
      currentAccount = nil
      isLoggedIn = false
      print("❌ AccountManagerIOS: Login state updated - isLoggedIn: false")
    }
  }

  // MARK: - Persistence

  private func loadFromStorage() {
    // Load accounts
    if let data = storage.data(forKey: accountsKey) {
      do {
        accounts = try JSONDecoder().decode([Account].self, from: data)
      } catch {
        print("Failed to load accounts: \(error)")
        accounts = []
      }
    }

    // Load active MID
    if storage.object(forKey: activeKey) != nil {
      let mid = storage.integer(forKey: activeKey)
      activeMID = accounts.contains(where: { $0.profile.mid == mid }) ? mid : nil
    }

    updateLoginState()
  }

  private func persistAll() {
    persistAccounts()
    persistActiveMID()
  }

  private func persistAccounts() {
    let encoder = JSONEncoder()
    if let data = try? encoder.encode(accounts) {
      storage.set(data, forKey: accountsKey)
    } else {
      storage.removeObject(forKey: accountsKey)
    }
  }

  private func persistActiveMID() {
    if let activeMID {
      storage.set(activeMID, forKey: activeKey)
    } else {
      storage.removeObject(forKey: activeKey)
    }
  }

  private func upsert(account: Account) {
    if let index = accounts.firstIndex(where: { $0.profile.mid == account.profile.mid }) {
      accounts[index] = account
    } else {
      accounts.append(account)
    }
  }

  private func updateAccount(mid: Int, update: (inout Account) -> Void) {
    guard let index = accounts.firstIndex(where: { $0.profile.mid == mid }) else { return }
    update(&accounts[index])
  }
}
