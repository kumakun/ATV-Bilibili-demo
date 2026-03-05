//
//  ContentView.swift
//  BilibiliLive-iOS
//
//  Created by niuniu on 2026/3/5.
//

import SwiftUI

struct ContentView: View {
  @State private var selectedTab = 0
  @State private var isLoggedIn = false

  var body: some View {
    if isLoggedIn {
      MainTabView(selectedTab: $selectedTab)
    } else {
      LoginView(isLoggedIn: $isLoggedIn)
    }
  }
}

#Preview {
  ContentView()
}
