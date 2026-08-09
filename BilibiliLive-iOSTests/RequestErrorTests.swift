//
//  RequestErrorTests.swift
//  BilibiliLive-iOSTests
//
//  Created by Codex on 2026/8/6.
//

import Foundation
import Testing
@testable import BilibiliLive_iOS

struct RequestErrorTests {

  @Test
  func exposesServerStatusInsteadOfGenericNSErrorDescription() {
    let error = RequestError.statusFail(code: -352, message: "风控校验失败")

    #expect(error.localizedDescription == "风控校验失败（错误码 -352）")
  }

  @Test
  func explainsExpiredLogin() {
    let error = RequestError.statusFail(code: -101, message: "账号未登录")

    #expect(error.localizedDescription == "登录状态已失效，请重新登录")
  }
}
