//
//  VideoCard.swift
//  BilibiliLive-iOS
//
//  Created on 2026/3/6.
//

import SwiftUI

struct VideoCard: View {
  let video: FavDataIOS

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // 封面图
      ZStack(alignment: .bottomTrailing) {
        AsyncImage(url: URL(string: video.cover)) { phase in
          switch phase {
          case .empty:
            Rectangle()
              .fill(Color.gray.opacity(0.2))
              .overlay {
                ProgressView()
              }
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          case .failure:
            Rectangle()
              .fill(Color.gray.opacity(0.2))
              .overlay {
                Image(systemName: "photo")
                  .foregroundStyle(.gray)
              }
          @unknown default:
            EmptyView()
          }
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 8))

        // 时长标签
        Text(video.durationText)
          .font(.caption2)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(.black.opacity(0.7))
          .foregroundStyle(.white)
          .cornerRadius(4)
          .padding(6)
      }

      // 标题
      Text(video.title)
        .font(.subheadline)
        .fontWeight(.medium)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)

      // UP主和数据
      HStack(spacing: 8) {
        if let upper = video.upper {
          Text(upper.name)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        Spacer()

        if let cntInfo = video.cntInfo {
          HStack(spacing: 4) {
            Image(systemName: "play.fill")
              .font(.caption2)
            Text(cntInfo.play.formattedPlayCount())
              .font(.caption)
          }
          .foregroundStyle(.secondary)
        }
      }
    }
    .padding(8)
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
  }
}

#Preview {
  VideoCard(
    video: FavDataIOS(
      id: 123456,
      title: "这是一个很长的视频标题示例，用来测试多行显示效果",
      cover: "https://via.placeholder.com/320x180",
      intro: "视频简介",
      duration: 3665,
      upper: FavDataIOS.Upper(mid: 1001, name: "测试UP主", face: ""),
      cntInfo: FavDataIOS.CntInfo(play: 123456, collect: 789),
      ogv: nil
    )
  )
  .padding()
}
