//
//  LoginView.swift
//  BilibiliLive-iOS
//
//  Created by niuniu on 2026/3/5.
//

import SwiftUI

struct LoginView: View {
  @Binding var isLoggedIn: Bool
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

          // 游客模式
          Button(action: {
            // 暂时直接跳过登录
            withAnimation {
              isLoggedIn = true
            }
          }) {
            Text("暂时跳过")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .padding(.top, 8)
        }
        .padding(.horizontal, 32)

        Spacer()
          .frame(height: 60)
      }
      .navigationTitle("")
      .sheet(isPresented: $showQRCode) {
        QRCodeLoginView(isLoggedIn: $isLoggedIn, isPresented: $showQRCode)
      }
    }
  }
}

// 二维码登录弹窗
struct QRCodeLoginView: View {
  @Binding var isLoggedIn: Bool
  @Binding var isPresented: Bool

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        Text("扫码登录")
          .font(.title2)
          .fontWeight(.semibold)

        // 二维码占位
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(.systemGray6))
          .frame(width: 240, height: 240)
          .overlay {
            VStack(spacing: 12) {
              Image(systemName: "qrcode")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
              Text("二维码占位")
                .foregroundStyle(.secondary)
            }
          }

        Text("请使用哔哩哔哩客户端\n扫描二维码登录")
          .multilineTextAlignment(.center)
          .foregroundStyle(.secondary)
          .font(.subheadline)

        // 临时测试按钮
        Button("模拟登录成功") {
          withAnimation {
            isLoggedIn = true
            isPresented = false
          }
        }
        .padding()
        .background(Color.pink)
        .foregroundColor(.white)
        .cornerRadius(8)
      }
      .padding()
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("取消") {
            isPresented = false
          }
        }
      }
    }
    .presentationDetents([.medium])
  }
}

#Preview {
  LoginView(isLoggedIn: .constant(false))
}
