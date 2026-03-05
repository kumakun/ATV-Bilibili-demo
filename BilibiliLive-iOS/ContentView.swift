//
//  ContentView.swift
//  BilibiliLive-iOS
//
//  Created by niuniu on 2026/3/5.
//

import SwiftUI

struct ContentView: View {
  @State private var selectedTab = 0
  @Environment(AccountManagerIOS.self) var accountManager

  var body: some View {
    if accountManager.isLoggedIn {
      MainTabView(selectedTab: $selectedTab)
    } else {
      LoginView()
    }
  }
}

#Preview {
  ContentView()
    .environment(AccountManagerIOS.shared)
}
