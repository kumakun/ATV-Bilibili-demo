//
//  MainTabView.swift
//  BilibiliLive-iOS
//
//  Created by niuniu on 2026/3/5.
//

import SwiftUI

struct MainTabView: View {
  @Binding var selectedTab: Int

  var body: some View {
    TabView(selection: $selectedTab) {
      FollowView()
        .tabItem {
          Label("关注", systemImage: "heart.fill")
        }
        .tag(0)

      FavoriteView()
        .tabItem {
          Label("收藏", systemImage: "star.fill")
        }
        .tag(1)

      ProfileView()
        .tabItem {
          Label("我的", systemImage: "person.fill")
        }
        .tag(2)
    }
    .tint(.pink)
  }
}

extension View {
  @ViewBuilder
  func secondaryPageTabBarHidden(_ hidden: Bool = true) -> some View {
    if hidden {
      toolbar(.hidden, for: .tabBar)
    } else {
      self
    }
  }
}

#Preview {
  MainTabView(selectedTab: .constant(0))
}
