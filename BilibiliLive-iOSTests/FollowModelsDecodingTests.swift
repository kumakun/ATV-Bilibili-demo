//
//  FollowModelsDecodingTests.swift
//  BilibiliLive-iOSTests
//
//  Created by Codex on 2026/8/6.
//

import Foundation
import Testing
@testable import BilibiliLive_iOS

struct FollowModelsDecodingTests {

  @Test
  func skipsUnsupportedFeedItemInsteadOfFailingEntirePage() throws {
    let data = Data(
      """
      {
        "items": [
          {
            "type": "DYNAMIC_TYPE_AV",
            "basic": { "comment_id_str": "1", "comment_type": 1 },
            "modules": {
              "module_author": {
                "face": "https://example.com/avatar.jpg",
                "mid": 1,
                "name": "作者",
                "pub_time": "刚刚"
              },
              "module_dynamic": {
                "major": {
                  "archive": {
                    "aid": "123",
                    "cover": "https://example.com/cover.jpg",
                    "title": "视频",
                    "duration_text": "01:00",
                    "stat": { "danmaku": "2", "play": "3" }
                  }
                }
              }
            },
            "id_str": "valid"
          },
          {
            "type": "DYNAMIC_TYPE_UNKNOWN",
            "modules": {},
            "id_str": "unsupported"
          }
        ],
        "offset": 456,
        "update_num": "7",
        "update_baseline": 123,
        "has_more": 1
      }
      """.utf8)

    let result = try JSONDecoder().decode(DynamicFeedInfo.self, from: data)

    #expect(result.items.map(\.id) == ["valid"])
    #expect(result.videoFeeds.map(\.aid) == [123])
    #expect(result.offset == "456")
    #expect(result.hasMore)
    #expect(result.updateNum == 7)
    #expect(result.updateBaseline == "123")
  }
}
