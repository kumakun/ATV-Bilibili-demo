//
//  QRCodeLoginViewModel.swift
//  BilibiliLive-iOS
//
//  Created by iOS Implementation on 2026/3/5.
//

import Foundation
import UIKit

@MainActor
@Observable
final class QRCodeLoginViewModel {
  // MARK: - Login State

  enum LoginState: Equatable {
    case idle
    case loading
    case success
    case failed(String)
    case expired
  }

  // MARK: - Published Properties

  var qrCodeImage: UIImage?
  var loginState: LoginState = .idle
  var errorMessage: String?

  // MARK: - Private Properties

  private var authCode: String = ""
  private var pollingTimer: Timer?
  private var pollCount: Int = 0
  private let maxPollCount: Int = 200

  // MARK: - Initialization

  init() {}

  // Note: deinit cannot be @MainActor, cleanup happens in onDisappear

  // MARK: - QR Code Generation

  func requestQRCode() {
    loginState = .loading
    errorMessage = nil

    ApiRequest.requestLoginQR { [weak self] authCode, url in
      guard let self else { return }

      Task { @MainActor in
        self.authCode = authCode
        self.qrCodeImage = QRCodeGenerator.generateQRCode(from: url)

        if self.qrCodeImage != nil {
          self.loginState = .idle
          self.startPolling()
        } else {
          self.loginState = .failed("Failed to generate QR code")
          self.errorMessage = "无法生成二维码，请重试"
        }
      }
    }
  }

  // MARK: - Polling

  func startPolling() {
    stopPolling()  // Stop any existing timer
    pollCount = 0

    pollingTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
      guard let self else { return }

      Task { @MainActor in
        await self.verifyLogin()
      }
    }
  }

  func stopPolling() {
    pollingTimer?.invalidate()
    pollingTimer = nil
    pollCount = 0
  }

  func verifyLogin() async {
    pollCount += 1

    // Check max poll count
    if pollCount > maxPollCount {
      stopPolling()
      loginState = .failed("Login timeout")
      errorMessage = "登录超时，请重新扫码"
      return
    }

    ApiRequest.verifyLoginQR(code: authCode) { [weak self] state in
      guard let self else { return }

      Task { @MainActor in
        switch state {
        case .waiting:
          // Still waiting for user to scan
          break

        case .expire:
          // QR code expired, request a new one
          self.stopPolling()
          self.loginState = .expired
          self.requestQRCode()  // Auto-refresh

        case .success(let token, let cookies):
          // Login successful
          self.stopPolling()
          self.handleLoginSuccess(token: token, cookies: cookies)

        case .fail:
          // Login failed
          self.stopPolling()
          self.loginState = .failed("Login failed")
          self.errorMessage = "登录失败，请重试"
        }
      }
    }
  }

  // MARK: - Login Success Handling

  private func handleLoginSuccess(token: LoginToken, cookies: [HTTPCookie]) {
    loginState = .loading

    AccountManagerIOS.shared.registerAccount(token: token, cookies: cookies) { [weak self] _ in
      guard let self else { return }

      Task { @MainActor in
        self.loginState = .success
      }
    }
  }

  // MARK: - Manual Refresh

  func refreshQRCode() {
    stopPolling()
    qrCodeImage = nil
    loginState = .idle
    errorMessage = nil
    requestQRCode()
  }
}
