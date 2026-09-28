import Foundation
import Testing
@testable import BilibiliLive_iOS

struct QRCodeLoginResponseTests {
  @Test(arguments: [86039, 86090])
  func pendingScanOrConfirmationKeepsPolling(code: Int) {
    let data = Data("{\"code\":\(code),\"message\":\"等待确认\",\"data\":null}".utf8)
    guard case .waiting = ApiRequest.parseLoginQRResponse(data) else {
      Issue.record("等待扫码或确认时不应终止登录")
      return
    }
  }

  @Test
  func expiredQRCodeRequestsRefresh() {
    guard case .expire = ApiRequest.parseLoginQRResponse(Data(#"{"code":86038}"#.utf8)) else {
      Issue.record("二维码过期应触发刷新")
      return
    }
  }

  @Test
  func serverFailurePreservesReasonAndCode() {
    let data = Data(#"{"code":-400,"message":"请求错误"}"#.utf8)
    guard case .fail(let message) = ApiRequest.parseLoginQRResponse(data) else {
      Issue.record("真正的服务端错误应终止登录")
      return
    }
    #expect(message == "请求错误（错误码 -400）")
  }

  @Test(arguments: ["{}", "<html>error</html>", #"{"code":0,"data":{}}"#])
  func malformedResponseCannotLogIn(response: String) {
    guard case .fail = ApiRequest.parseLoginQRResponse(Data(response.utf8)) else {
      Issue.record("无效响应不能被当作登录成功")
      return
    }
  }

  @Test
  func confirmedLoginDecodesCredentials() {
    let data = Data(#"""
      {"code":0,"data":{
        "token_info":{"mid":123,"access_token":"test-access","refresh_token":"test-refresh","expires_in":3600},
        "cookie_info":{"domains":[".bilibili.com"],"cookies":[
          {"name":"SESSDATA","value":"test-session","http_only":1,"expires":2000000000}
        ]}
      }}
      """#.utf8)
    guard case .success(let token, let cookies) = ApiRequest.parseLoginQRResponse(data) else {
      Issue.record("确认后应解析凭据并完成登录")
      return
    }
    #expect(token.mid == 123)
    #expect(token.accessToken == "test-access")
    #expect(token.expireDate != nil)
    #expect(cookies.first?.name == "SESSDATA")
    #expect(cookies.first?.value == "test-session")
  }
}
