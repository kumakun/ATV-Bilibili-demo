//
//  WatchLaterView.swift
//  BilibiliLive-iOS
//
//  Created on 2026/3/5.
//

import SwiftUI

struct WatchLaterView: View {
  @State private var viewModel = WatchLaterViewModel()
  @State private var itemToDelete: WatchLaterItem?
  @State private var showDeleteConfirmation = false

  var body: some View {
    Group {
      if viewModel.isLoading && viewModel.watchLaterItems.isEmpty {
        ProgressView()
      } else if let errorMessage = viewModel.errorMessage, viewModel.watchLaterItems.isEmpty {
        VStack(spacing: 16) {
          Text(errorMessage)
            .foregroundColor(.secondary)
          Button("重试") {
            Task {
              await viewModel.load()
            }
          }
        }
      } else if viewModel.watchLaterItems.isEmpty {
        Text("暂无稍后再看")
          .foregroundColor(.secondary)
      } else {
        List {
          ForEach(viewModel.watchLaterItems) { item in
            NavigationLink(value: ProfileRoute.videoDetail(aid: item.aid)) {
              WatchLaterRow(item: item, viewModel: viewModel)
            }
            .contextMenu {
              Button(role: .destructive) {
                itemToDelete = item
                showDeleteConfirmation = true
              } label: {
                Label("删除", systemImage: "trash")
              }
            }
          }
        }
        .listStyle(.plain)
        .refreshable {
          await viewModel.refresh()
        }
      }
    }
    .navigationTitle("稍后再看")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.load()
    }
    .alert("确认删除", isPresented: $showDeleteConfirmation, presenting: itemToDelete) { item in
      Button("取消", role: .cancel) {}
      Button("删除", role: .destructive) {
        Task {
          do {
            try await viewModel.delete(item: item)
          } catch {
            print("Failed to delete item: \(error)")
          }
        }
      }
    } message: { item in
      Text("确定要删除「\(item.title)」吗？")
    }
  }
}

struct WatchLaterRow: View {
  let item: WatchLaterItem
  let viewModel: WatchLaterViewModel

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      // 封面
      AsyncImage(url: item.picURL) { image in
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      } placeholder: {
        Color.gray.opacity(0.2)
      }
      .frame(width: 120, height: 68)
      .clipShape(RoundedRectangle(cornerRadius: 6))

      // 视频信息
      VStack(alignment: .leading, spacing: 4) {
        Text(item.title)
          .font(.system(size: 15))
          .lineLimit(2)

        HStack(spacing: 4) {
          Text(item.ownerName)
            .font(.system(size: 13))
            .foregroundColor(.secondary)

          Text("·")
            .foregroundColor(.secondary)

          Text(viewModel.publishDateText(for: item))
            .font(.system(size: 13))
            .foregroundColor(.secondary)
        }

        HStack(spacing: 8) {
          // 时长
          Text(viewModel.durationText(for: item))
            .font(.system(size: 12))
            .foregroundColor(.secondary)

          // 统计信息
          if let stat = item.stat {
            Text("·")
              .foregroundColor(.secondary)
            Text("\(stat.view)播放")
              .font(.system(size: 12))
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  NavigationStack {
    WatchLaterView()
  }
}
