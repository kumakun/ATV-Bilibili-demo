//
//  WatchHistoryView.swift
//  BilibiliLive-iOS
//
//  Created by iOS Implementation on 2026/3/5.
//

import SwiftUI

struct WatchHistoryView: View {
  @State private var viewModel = WatchHistoryViewModel()

  var body: some View {
    Group {
      if viewModel.isLoading && viewModel.items.isEmpty {
        ProgressView("加载中...")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let error = viewModel.errorMessage, viewModel.items.isEmpty {
        VStack(spacing: 12) {
          Text(error)
            .foregroundStyle(.secondary)
          Button("重试") {
            Task { await viewModel.load() }
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if viewModel.items.isEmpty {
        ContentUnavailableView("暂无历史记录", systemImage: "clock.arrow.circlepath")
      } else {
        List(viewModel.items) { item in
          NavigationLink(value: item) {
            HistoryRow(
              item: item, progress: viewModel.progressText(for: item),
              timeText: viewModel.relativeTimeText(for: item))
          }
        }
        .listStyle(.plain)
        .refreshable {
          await viewModel.refresh()
        }
      }
    }
    .navigationTitle("历史记录")
    .navigationBarTitleDisplayMode(.inline)
    .navigationDestination(for: HistoryItem.self) { item in
      HistoryDetailPlaceholderView(item: item)
    }
    .onAppear {
      Task { await viewModel.load() }
    }
  }
}

private struct HistoryRow: View {
  let item: HistoryItem
  let progress: String
  let timeText: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      AsyncImage(url: item.picURL) { image in
        image.resizable().scaledToFill()
      } placeholder: {
        RoundedRectangle(cornerRadius: 8).fill(.gray.opacity(0.25))
      }
      .frame(width: 120, height: 68)
      .clipShape(RoundedRectangle(cornerRadius: 8))

      VStack(alignment: .leading, spacing: 6) {
        Text(item.title)
          .font(.subheadline)
          .fontWeight(.medium)
          .lineLimit(2)

        Text(item.ownerName)
          .font(.caption)
          .foregroundStyle(.secondary)

        HStack(spacing: 8) {
          Text(progress)
          Text("·")
          Text(timeText)
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 4)
  }
}

private struct HistoryDetailPlaceholderView: View {
  let item: HistoryItem

  var body: some View {
    VStack(spacing: 12) {
      Text(item.title)
        .font(.headline)
      Text("视频详情页待对接")
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
    .navigationTitle("视频详情")
    .secondaryPageTabBarHidden()
  }
}
