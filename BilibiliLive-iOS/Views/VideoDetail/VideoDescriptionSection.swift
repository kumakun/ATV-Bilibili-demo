//
//  VideoDescriptionSection.swift
//  BilibiliLive-iOS
//
//  Created by GitHub Copilot on 2026/3/6.
//

import SwiftUI

struct VideoDescriptionSection: View {
  let description: String
  @State private var isExpanded = false

  private let lineLimit = 3

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("简介")
        .font(.subheadline)
        .fontWeight(.semibold)

      Text(description)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(isExpanded ? nil : lineLimit)

      if description.split(separator: "\n").count > lineLimit || description.count > 100 {
        Button(action: { isExpanded.toggle() }) {
          Text(isExpanded ? "收起" : "展开")
            .font(.caption)
            .foregroundColor(.blue)
        }
      }
    }
    .padding(.horizontal)
  }
}

#Preview {
  VideoDescriptionSection(
    description: "这是一段很长的视频简介文本。\n这是第二行。\n这是第三行。\n这是第四行，应该被折叠。"
  )
}
