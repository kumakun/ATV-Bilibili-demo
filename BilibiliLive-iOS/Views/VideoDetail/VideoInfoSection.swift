//
//  VideoInfoSection.swift
//  BilibiliLive-iOS
//
//  Created by GitHub Copilot on 2026/3/6.
//

import SwiftUI

struct VideoInfoSection: View {
  let videoInfo: VideoDetail.VideoInfo

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // 标题
      Text(videoInfo.title)
        .font(.headline)
        .fontWeight(.semibold)
        .lineLimit(2)

      // 时长和BVID
      HStack(spacing: 16) {
        if let bvid = videoInfo.bvid {
          Text(bvid)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Text(videoInfo.durationString)
          .font(.caption)
          .foregroundStyle(.secondary)

        if let pubdate = videoInfo.pubdateString {
          Text(pubdate)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.horizontal)
  }
}

#Preview {
  VideoInfoSection(
    videoInfo: VideoDetail.VideoInfo(
      aid: 123,
      cid: 456,
      title: "测试视频标题",
      videos: 1,
      pic: nil,
      desc: "这是一个测试描述",
      owner: VideoOwner(mid: 1, name: "测试UP主", face: nil),
      pages: nil,
      dynamic: nil,
      bvid: "BV1xx411c7mD",
      duration: 120,
      pubdate: 1_234_567_890,
      ugc_season: nil,
      redirect_url: nil,
      stat: VideoDetail.VideoInfo.VideoStat(
        favorite: 100,
        coin: 200,
        like: 300,
        share: 50,
        danmaku: 150,
        view: 1000
      ),
      ctime: nil
    )
  )
}
