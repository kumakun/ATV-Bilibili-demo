//
//  VideoEpisodesSection.swift
//  BilibiliLive-iOS
//
//  Created by GitHub Copilot on 2026/3/6.
//

import SwiftUI

struct VideoEpisodesSection: View {
  let pages: [VideoPage]
  let currentPageIndex: Int
  let onPageTap: (Int) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("选集（\(pages.count)P）")
        .font(.subheadline)
        .fontWeight(.semibold)
        .padding(.horizontal)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
            EpisodeCell(
              page: page,
              isSelected: index == currentPageIndex,
              action: { onPageTap(index) }
            )
          }
        }
        .padding(.horizontal)
      }
    }
  }
}

private struct EpisodeCell: View {
  let page: VideoPage
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 4) {
        Text(page.displayTitle)
          .font(.caption)
          .fontWeight(isSelected ? .semibold : .regular)
          .lineLimit(2)
          .foregroundColor(isSelected ? .white : .primary)
          .frame(width: 120, alignment: .leading)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(isSelected ? Color.pink : Color(.systemGray6))
      .cornerRadius(8)
    }
  }
}

#Preview {
  VideoEpisodesSection(
    pages: [
      VideoPage(cid: 1, page: 1, epid: nil, from: "", part: "第1集 开始"),
      VideoPage(cid: 2, page: 2, epid: nil, from: "", part: "第2集 继续"),
      VideoPage(cid: 3, page: 3, epid: nil, from: "", part: "第3集 发展"),
      VideoPage(cid: 4, page: 4, epid: nil, from: "", part: "第4集 高潮"),
      VideoPage(cid: 5, page: 5, epid: nil, from: "", part: "第5集 结局"),
    ],
    currentPageIndex: 1,
    onPageTap: { _ in }
  )
}
