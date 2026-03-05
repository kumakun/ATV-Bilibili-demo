//
//  LoginView.swift
//  BilibiliLive-iOS
//
//  Created by niuniu on 2026/3/5.
//

import SwiftUI

struct LoginView: View {
  @State private var showQRCode = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 30) {
        Spacer()

        // Logo区域
        VStack(spacing: 16) {
          Image(systemName: "play.rectangle.fill")
            .font(.system(size: 80))
            .foregroundStyle(.pink)

          Text("哔哩哔哩")
            .font(.largeTitle)
            .fontWeight(.bold)

          Text("干杯 ~")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Spacer()

        // 登录按钮区域
        VStack(spacing: 16) {
          // 二维码登录按钮
          Button(action: {
            showQRCode = true
          }) {
            HStack {
              Image(systemName: "qrcode")
              Text("扫码登录")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.pink)
            .foregroundColor(.white)
            .cornerRadius(12)
          }

          // 密码登录按钮
          Button(action: {
            // 暂无功能
          }) {
            HStack {
              Image(systemName: "person.circle")
              Text("密码登录")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .foregroundColor(.primary)
            .cornerRadius(12)
          }
        }
        .padding(.horizontal, 32)

        Spacer()
          .frame(height: 60)
      }
      .navigationTitle("")
      .sheet(isPresented: $showQRCode) {
        QRCodeLoginView(isPresented: $showQRCode)
      }
    }
  }
}

// 二维码登录弹窗
struct QRCodeLoginView: View {
  @Binding var isPresented: Bool
  @State private var viewModel = QRCodeLoginViewModel()

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        Text("扫码登录")
          .font(.title2)
          .fontWeight(.semibold)

        // 二维码显示区域
        ZStack {
          // 白色背景容器（确保深色模式下可见）
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.white)
            .frame(width: 260, height: 260)

          if let qrImage = viewModel.qrCodeImage {
            // 真实二维码
            Image(uiImage: qrImage)
              .interpolation(.none)
              .resizable()
              .scaledToFit()
              .frame(width: 240, height: 240)
          } else if viewModel.loginState == .loading {
            // 加载状态
            ProgressView()
              .scaleEffect(1.5)
          } else {
            // 错误状态
            VStack(spacing: 12) {
              Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
              Text("加载失败")
                .foregroundStyle(.secondary)
            }
          }
        }

        // 说明文字
        Text("请使用哔哩哔哩客户端\n扫描二维码登录")
          .multilineTextAlignment(.center)
          .foregroundStyle(.secondary)
          .font(.subheadline)

        // 错误提示
        if let errorMessage = viewModel.errorMessage {
          Text(errorMessage)
            .font(.caption)
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
        }

        // 刷新按钮
        Button(action: {
          viewModel.refreshQRCode()
        }) {
          HStack {
            Image(systemName: "arrow.clockwise")
            Text("重新生成二维码")
          }
          .padding()
          .background(Color(.systemGray6))
          .foregroundColor(.primary)
          .cornerRadius(8)
        }
      }
      .padding()
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("取消") {
            isPresented = false
          }
        }
      }
      .onAppear {
        viewModel.requestQRCode()
      }
      .onDisappear {
        viewModel.stopPolling()
      }
      .onChange(of: viewModel.loginState) { _, newState in
        if newState == .success {
          // Close the sheet, ContentView will automatically switch to MainTabView
          // because AccountManagerIOS.isLoggedIn is now true
          isPresented = false
        }
      }
    }
    .presentationDetents([.medium])
  }
}

#Preview {
  LoginView()
}
