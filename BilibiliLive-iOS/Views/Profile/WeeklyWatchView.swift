//
//  WeeklyWatchView.swift
//  BilibiliLive-iOS
//
//  Created on 2026/3/5.
//

import SwiftUI

struct WeeklyWatchView: View {
  @State private var viewModel = WeeklyWatchViewModel()

  var body: some View {
    VStack(spacing: 0) {
      // 每周期数选择器
      if !viewModel.weeklyList.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            ForEach(viewModel.weeklyList) { weekly in
              Button {
                Task {
                  await viewModel.selectWeekly(weekly)
                }
              } label: {
                VStack(spacing: 4) {
                  Text(weekly.name)
                    .font(.system(size: 14, weight: .medium))
                  Text(weekly.subject)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                  viewModel.selectedWeekly?.number == weekly.number
                    ? Color.accentColor.opacity(0.15)
                    : Color.gray.opacity(0.1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
              }
              .buttonStyle(.plain)
            }
          }
          .padding(.horizontal)
          .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))

        Divider()
      }

      // 视频列表
      Group {
        if viewModel.isLoadingList && viewModel.weeklyList.isEmpty {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let errorMessage = viewModel.errorMessage, viewModel.weeklyList.isEmpty {
          VStack(spacing: 16) {
            Text(errorMessage)
              .foregroundColor(.secondary)
            Button("重试") {
              Task {
                await viewModel.loadWeeklyList()
              }
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.weeklyVideos.isEmpty && viewModel.isLoadingVideos {
          ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.weeklyVideos.isEmpty {
          Text("暂无推荐")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          ScrollView {
            LazyVStack(spacing: 12) {
              ForEach(viewModel.weeklyVideos) { video in
                NavigationLink(value: ProfileRoute.videoDetail(aid: video.aid)) {
                  WeeklyVideoRow(video: video, viewModel: viewModel)
                }
                .buttonStyle(.plain)
              }
            }
            .padding()
          }
          .refreshable {
            await viewModel.refresh()
          }
        }
      }
    }
    .navigationTitle("每周必看")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.loadWeeklyList()
    }
  }
}

struct WeeklyVideoRow: View {
  let video: WeeklyVideo
  let viewModel: WeeklyWatchViewModel

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      // 封面
      AsyncImage(url: video.picURL) { image in
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
        Text(video.title)
          .font(.system(size: 15))
          .lineLimit(2)
          .foregroundColor(.primary)

        Text(video.owner.name)
          .font(.system(size: 13))
          .foregroundColor(.secondary)

        if let stat = video.stat {
          HStack(spacing: 8) {
            Text("\(viewModel.formatCount(stat.view))播放")
              .font(.system(size: 12))
              .foregroundColor(.secondary)

            Text("·")
              .foregroundColor(.secondary)

            Text("\(viewModel.formatCount(stat.danmaku))弹幕")
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
    WeeklyWatchView()
  }
}
