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
}
