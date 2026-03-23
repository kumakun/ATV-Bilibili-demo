//
//  ProfileRouteTests.swift
//  BilibiliLive-iOSTests
//
//  Created by Codex on 2026/3/23.
//

import Testing
@testable import BilibiliLive_iOS

struct ProfileRouteTests {

  @Test
  func primaryRoutesMatchVisibleProfileFeatures() {
    let titles = ProfileRoute.primaryRoutes.map(\.menuItem.title)

    #expect(titles == ["关注UP", "追番追剧", "历史记录", "稍后再看"])
  }
}
