## 1. 准备数据模型和工具类

- [x] 1.1 创建 `BilibiliLive-iOS/Models/` 目录
- [x] 1.2 创建 `LoginModels.swift` 文件，定义 Account、Profile、LoginToken、StoredCookie 数据结构（复用 tvOS 的定义，确保 Codable）
- [x] 1.3 创建 `BilibiliLive-iOS/Utilities/` 目录
- [x] 1.4 实现 `QRCodeGenerator.swift`，包含 `generateQRCode(from: String) -> UIImage?` 方法，使用 CoreImage 的 CIQRCodeGenerator

## 2. 实现账号管理模块

- [x] 2.1 创建 `AccountManagerIOS.swift` 文件，使用 `@Observable` 宏标注类
- [x] 2.2 添加 `@MainActor` 确保在主线程执行
- [x] 2.3 实现核心属性：`isLoggedIn`、`currentAccount`、`accounts`（存储属性，自动可观察）
- [x] 2.4 实现单例模式 `static let shared = AccountManagerIOS()`
- [x] 2.5 实现 `bootstrap()` 方法：从 UserDefaults 加载账号数据，自动激活最近使用的账号
- [x] 2.6 实现 `registerAccount(token:cookies:completion:)` 方法：调用用户信息 API，创建账号记录，设置为活跃账号
- [x] 2.7 实现持久化方法：`persistAccounts()` 和 `loadAccounts()`，使用 UserDefaults 的 "ios.accounts" 键
- [x] 2.8 实现 `setActiveAccount(mid:)` 方法：更新活跃账号，应用 cookies 到 CookieHandler
- [x] 2.9 实现 `removeAccount(_:)` 和 `removeAllAccounts()` 方法
- [x] 2.10 实现 `updateActiveProfile(username:avatar:)` 和 `refreshActiveAccountProfile()` 方法
- [x] 2.11 实现 `handleAuthenticationFailure()` 方法：处理 token 过期，移除失效账号

## 3. 实现二维码登录 ViewModel

- [x] 3.1 创建 `BilibiliLive-iOS/ViewModels/` 目录
- [x] 3.2 创建 `QRCodeLoginViewModel.swift` 文件，使用 `@Observable` 宏
- [x] 3.3 添加 `@MainActor` 确保在主线程执行
- [x] 3.4 定义登录状态枚举 `LoginState`：idle、loading、success、failed、expired
- [x] 3.5 实现属性：`qrCodeImage`、`loginState`、`errorMessage`、`authCode`、`pollingTimer`、`pollCount`
- [x] 3.6 实现 `requestQRCode()` 方法：调用 `ApiRequest.requestLoginQR`，生成二维码图像，启动轮询
- [x] 3.7 实现 `startPolling()` 方法：创建 Timer，每 4 秒调用 `verifyLogin()`
- [x] 3.8 实现 `verifyLogin()` 方法：调用 `ApiRequest.verifyLoginQR`，处理不同状态（waiting、expire、success、fail）
- [x] 3.9 实现登录成功逻辑：调用 `AccountManagerIOS.shared.registerAccount`，停止轮询，更新状态
- [x] 3.10 实现二维码过期处理：自动调用 `requestQRCode()` 重新生成
- [x] 3.11 实现 `stopPolling()` 方法：取消 Timer，重置计数器
- [x] 3.12 实现 `refreshQRCode()` 方法：手动刷新二维码（停止轮询 → 重新请求）
- [x] 3.13 添加最大轮询次数检查（200 次），超时后显示错误提示

## 4. 更新二维码登录视图

- [x] 4.1 打开 `QRCodeLoginView.swift`，添加 `@State var viewModel = QRCodeLoginViewModel()`
- [x] 4.2 移除占位的 `RoundedRectangle` 和 "二维码占位" 文本
- [x] 4.3 使用 `viewModel.qrCodeImage` 显示真实二维码（使用 `Image(uiImage:)`）
- [x] 4.4 添加加载状态指示器：根据 `viewModel.loginState` 显示 `ProgressView()`
- [x] 4.5 添加错误提示：根据 `viewModel.errorMessage` 显示错误信息
- [x] 4.6 移除 "模拟登录成功" 按钮
- [x] 4.7 添加 "重新生成二维码" 按钮，调用 `viewModel.refreshQRCode()`
- [x] 4.8 在 `.onAppear` 中调用 `viewModel.requestQRCode()` 初始化二维码
- [x] 4.9 在 `.onDisappear` 中调用 `viewModel.stopPolling()` 清理资源
- [x] 4.10 监听 `viewModel.loginState`，登录成功时关闭弹窗（`isPresented = false`）并更新 `isLoggedIn = true`
- [x] 4.11 优化二维码显示：添加白色背景容器，确保深色模式下可见

## 5. 更新登录主界面

- [x] 5.1 打开 `LoginView.swift`，移除 "暂时跳过" 按钮和功能
- [x] 5.2 确认 "扫码登录" 按钮正确触发 `showQRCode = true`
- [x] 5.3 确认 `.sheet(isPresented: $showQRCode)` 正确传递 `isLoggedIn` 绑定
- [x] 5.4 优化 UI 布局和样式（可选）

## 6. 集成账号管理到应用入口

- [x] 6.1 打开 `BilibiliLive_iOSApp.swift`
- [x] 6.2 添加 `@State private var accountManager = AccountManagerIOS.shared`
- [x] 6.3 使用 `.environment(accountManager)` 将 AccountManager 注入环境
- [x] 6.4 在应用启动时调用 `accountManager.bootstrap()` 初始化账号状态

## 7. 更新 ContentView 集成登录状态

- [x] 7.1 打开 `ContentView.swift`
- [x] 7.2 移除 `@State private var isLoggedIn = false`
- [x] 7.3 添加 `@Environment(AccountManagerIOS.self) var accountManager`
- [x] 7.4 修改条件判断：使用 `accountManager.isLoggedIn` 替代本地 `isLoggedIn`
- [x] 7.5 更新 `LoginView` 的 `isLoggedIn` 绑定，改为监听 `accountManager.isLoggedIn` 的变化
- [x] 7.6 确保登录状态变化时自动切换视图

## 8. 测试核心功能

- [x] 8.1 测试二维码生成：打开登录界面，验证二维码正确显示
- [x] 8.2 测试手动刷新：点击 "重新生成二维码" 按钮，验证二维码更新
- [x] 8.3 测试扫码登录流程：使用哔哩哔哩官方 App 扫码，验证登录成功
- [x] 8.4 测试登录后状态：验证应用切换到 MainTabView
- [ ] 8.5 测试账号持久化：重启应用，验证登录状态保持
- [ ] 8.6 测试取消登录：在二维码界面点击取消，验证返回登录页面
- [ ] 8.7 测试二维码过期：等待二维码过期，验证自动刷新

## 9. 错误处理和边界情况

- [ ] 9.1 测试网络错误：断开网络，验证错误提示显示
- [ ] 9.2 测试 API 失败：验证 `verifyLoginQR` 失败时的处理
- [ ] 9.3 测试后台行为：切换到后台再返回，验证 Timer 恢复或重启
- [ ] 9.4 测试最大轮询次数：等待 800 秒（或模拟），验证超时提示
- [ ] 9.5 测试用户资料获取失败：验证使用默认资料（UID {mid}）
- [ ] 9.6 添加适当的错误日志和调试信息

## 10. UI/UX 优化

- [ ] 10.1 优化二维码显示尺寸和样式（建议 240x240）
- [ ] 10.2 优化加载动画和过渡效果
- [ ] 10.3 添加登录成功的提示动画或反馈
- [ ] 10.4 优化深色模式下的二维码对比度（白色背景容器）
- [ ] 10.5 优化说明文字的可读性和布局
- [ ] 10.6 测试不同屏幕尺寸（iPhone SE、Pro Max 等）
- [ ] 10.7 优化按钮样式和交互反馈
- [ ] 10.8 确保无障碍支持（VoiceOver 等）
