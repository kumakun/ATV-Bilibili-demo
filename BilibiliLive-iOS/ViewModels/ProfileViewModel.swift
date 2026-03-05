//
//  ProfileViewModel.swift
//  BilibiliLive-iOS
//
//  Created by iOS Implementation on 2026/3/5.
//

import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
  // MARK: - Properties

  var userProfile: UserProfile?
  var isLoading = false
  var errorMessage: String?
  var logoutError: String?

  private let accountManager = AccountManagerIOS.shared

  // MARK: - Computed Properties

  var isLoggedIn: Bool {
    accountManager.isLoggedIn
  }

  var currentAccount: AccountManagerIOS.Account? {
    accountManager.currentAccount
  }

  var displayName: String {
    if let profile = userProfile {
      return profile.username
    }
    return currentAccount?.profile.username ?? "未登录"
  }

  var avatarURL: URL? {
    if let profile = userProfile, !profile.avatar.isEmpty {
      return URL(string: profile.avatar)
    }
    if let avatar = currentAccount?.profile.avatar, !avatar.isEmpty {
      return URL(string: avatar)
    }
    return nil
  }

  var signature: String {
    userProfile?.sign ?? "这是一段个人签名..."
  }

  var followingCount: String {
    if let count = userProfile?.following {
      return formatCount(count)
    }
    return "0"
  }

  var followerCount: String {
    if let count = userProfile?.follower {
      return formatCount(count)
    }
    return "0"
  }

  var likesCount: String {
    if let count = userProfile?.likes {
      return formatCount(count)
    }
    return "0"
  }

  // MARK: - Methods

  func loadProfile() async {
    guard let mid = currentAccount?.profile.mid else {
      errorMessage = "未登录"
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      userProfile = try await WebRequest.requestUserInfo(mid: mid)
    } catch {
      errorMessage = "加载失败: \(error.localizedDescription)"
      print("Failed to load profile: \(error)")
    }

    isLoading = false
  }

  func logout() async {
    do {
      try await WebRequest.logout()
    } catch {
      logoutError = "登出失败: \(error.localizedDescription)"
    }
  }

  func refreshProfile() async {
    // Refresh account info from server
    guard let mid = currentAccount?.profile.mid else { return }

    do {
      userProfile = try await WebRequest.requestUserInfo(mid: mid)
    } catch {
      print("Failed to refresh profile: \(error)")
    }
  }

  private func formatCount(_ count: Int) -> String {
    if count >= 10000 {
      let value = Double(count) / 10000.0
      return String(format: "%.1f万", value)
    }
    return "\(count)"
  }
}
