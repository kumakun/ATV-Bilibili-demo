//
//  UploaderInfoView.swift
//  BilibiliLive-iOS
//
//  Created by GitHub Copilot on 2026/3/6.
//

import SwiftUI

struct UploaderInfoView: View {
  let owner: VideoOwner
  let isFollowing: Bool
  let onFollowTap: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      // UP主头像
      AsyncImage(url: owner.face.flatMap { URL(string: $0) }) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        Color.gray.opacity(0.3)
      }
      .frame(width: 40, height: 40)
      .clipShape(Circle())

      // UP主名称
      Text(owner.name)
        .font(.subheadline)
        .fontWeight(.medium)

      Spacer()

      // 关注按钮
      Button(action: onFollowTap) {
        Text(isFollowing ? "已关注" : "关注")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundColor(isFollowing ? .secondary : .white)
          .padding(.horizontal, 16)
          .padding(.vertical, 6)
          .background(isFollowing ? Color(.systemGray5) : Color.pink)
          .cornerRadius(15)
      }
    }
    .padding(.horizontal)
  }
}

#Preview {
  VStack {
    UploaderInfoView(
      owner: VideoOwner(mid: 1, name: "测试UP主", face: nil),
      isFollowing: false,
      onFollowTap: {}
    )

    UploaderInfoView(
      owner: VideoOwner(mid: 1, name: "测试UP主", face: nil),
      isFollowing: true,
      onFollowTap: {}
    )
  }
}
