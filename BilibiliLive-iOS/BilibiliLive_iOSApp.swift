//
//  BilibiliLive_iOSApp.swift
//  BilibiliLive-iOS
//
//  Created by niuniu on 2026/3/5.
//

import SwiftUI

@main
struct BilibiliLive_iOSApp: App {
  @State private var accountManager = AccountManagerIOS.shared

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(accountManager)
        .onAppear {
          accountManager.bootstrap()
        }
    }
  }
}
