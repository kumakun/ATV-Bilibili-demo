## 上下文

iOS 平台目前已有基础的 SwiftUI 应用框架（`BilibiliLive-iOS` target），包括 `ContentView`、`MainTabView` 和占位的 `LoginView`。tvOS 平台有成熟的 UIKit 登录实现（`LoginViewController`），但不能直接复用，因为：

1. **UI 框架差异**：tvOS 使用 UIKit，iOS 版本采用 SwiftUI
2. **交互模式差异**：tvOS 使用遥控器焦点导航，iOS 使用触摸交互
3. **架构设计**：iOS 需要使用 SwiftUI 的声明式架构和状态管理

现有资源：
- `ApiRequest.swift` 提供 `requestLoginQR` 和 `verifyLoginQR` 方法（可复用）
- `AccountManager.swift` 提供账号管理逻辑（需为 iOS 重写以适配 SwiftUI）
- `CookieHandler` 和 `StoredCookie` 用于 Cookie 管理（可复用）

约束：
- 必须编写独立的 iOS 代码，不与 tvOS 共享 UI 层代码
- 必须使用 SwiftUI 作为 UI 框架
- 必须遵循相同的 API 接口和登录流程逻辑

## 目标 / 非目标

**目标：**
- 为 iOS 平台实现功能完整的二维码扫码登录
- 创建 SwiftUI 友好的账号管理模块（@Observable）
- 实现登录状态持久化和自动恢复
- 提供清晰的用户反馈（加载状态、错误提示、二维码过期处理）
- 支持手动刷新二维码
- 集成登录状态到应用的主导航流程

**非目标：**
- 实现密码登录（保留为未来功能）
- 多账号切换功能（可作为未来增强）
- 与 tvOS 共享代码（两个平台独立实现）
- 生物识别登录（Face ID / Touch ID）
- 账号同步到 iCloud

## 决策

### 决策 1：使用 @Observable 宏管理账号状态

**选择：** 创建 `AccountManagerIOS` 类使用 `@Observable` 宏，让属性自动支持观察。

**理由：**
- Swift 5.9+ 的现代状态管理方式，语法更简洁
- 无需 `@Published` 包装器，所有存储属性自动可观察
- 更好的性能，只在真正使用的属性变化时触发更新
- 遵循 SwiftUI 的最新最佳实践

**替代方案：**
- **使用 ObservableObject 协议**：旧的方式，需要手动添加 @Published，代码冗余
- **重用 tvOS 的 AccountManager + NotificationCenter**：不推荐，因为需要在 SwiftUI 中手动管理通知订阅
- **使用全局 @AppStorage**：不推荐，难以管理复杂的账号数据结构

**实现：**
```swift
@MainActor
@Observable
class AccountManagerIOS {
    var isLoggedIn: Bool = false
    var currentAccount: Account?
    var accounts: [Account] = []
    
    static let shared = AccountManagerIOS()
}
```

### 决策 2：使用 ViewModel 模式管理二维码登录逻辑

**选择：** 创建 `QRCodeLoginViewModel` 使用 `@Observable` 宏，封装二维码生成、轮询和状态管理。

**理由：**
- 分离业务逻辑和视图层，提高可测试性
- 集中管理定时器和网络请求的生命周期
- 便于管理复杂的登录状态（加载中、成功、失败、过期）
- 使用 @Observable 让代码更简洁，无需 @Published 包装

**替代方案：**
- **直接在 View 中使用 @State 管理**：不推荐，View 会变得臃肿且难以测试
- **使用 Combine Publisher**：过度工程化，增加复杂度

**实现：**
```swift
@MainActor
@Observable
class QRCodeLoginViewModel {
    var qrCodeImage: UIImage?
    var loginState: LoginState = .idle
    var errorMessage: String?
    
    private var authCode: String = ""
    private var pollingTimer: Timer?
    private var pollCount: Int = 0
    private let maxPollCount: Int = 200
}
```

### 决策 3：使用 Timer 进行轮询而非 Combine

**选择：** 使用 `Timer.publish` 或 `Timer.scheduledTimer` 进行每 4 秒的登录状态轮询。

**理由：**
- 简单直观，符合 tvOS 实现的逻辑
- 易于控制启动和停止
- 降低学习曲线，不需要深入理解 Combine

**替代方案：**
- **Combine Timer Publisher**：可以使用，但增加复杂度且收益不大
- **async/await + Task.sleep**：可行，但需要管理 Task 取消，相比 Timer 没有明显优势

**实现：**
```swift
func startPolling() {
    pollingTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
        Task { @MainActor in
            await self?.verifyLogin()
        }
    }
}
```

### 决策 4：复用现有的 ApiRequest 方法

**选择：** 直接调用 `ApiRequest.requestLoginQR` 和 `ApiRequest.verifyLoginQR`，不重写网络层。

**理由：**
- API 接口和逻辑与 tvOS 完全一致，无需重复代码
- 已经过测试和验证，稳定可靠
- 减少维护成本

**替代方案：**
- **重写为 async/await 风格的 API**：不推荐，需要大量重构现有代码
- **使用 Combine 包装现有 API**：增加不必要的复杂度

**实现：**
```swift
func requestQRCode() {
    ApiRequest.requestLoginQR { [weak self] authCode, url in
        Task { @MainActor in
            self?.authCode = authCode
            self?.qrCodeImage = self?.generateQRCode(from: url)
            self?.startPolling()
        }
    }
}
```

### 决策 5：数据持久化使用 UserDefaults + Codable

**选择：** 使用 `UserDefaults` 存储账号数据，使用 `JSONEncoder/JSONDecoder` 进行序列化。

**理由：**
- 与 tvOS 实现保持一致，便于未来可能的数据迁移
- UserDefaults 足够满足账号数据的存储需求
- Codable 提供类型安全的序列化

**替代方案：**
- **使用 Keychain**：可以用于敏感数据（token），但当前 tvOS 也使用 UserDefaults，保持一致
- **使用 CoreData**：过度工程化，账号数据不需要关系型数据库
- **使用文件系统**：增加复杂度，没有明显优势

**实现：**
```swift
private func persistAccounts() {
    let encoder = JSONEncoder()
    if let data = try? encoder.encode(accounts) {
        UserDefaults.standard.set(data, forKey: "ios.accounts")
    }
}
```

### 决策 6：使用 Sheet 弹窗展示二维码登录

**选择：** 使用 SwiftUI 的 `.sheet` modifier 展示二维码登录界面。

**理由：**
- 符合 iOS 的模态交互设计规范
- 提供清晰的视觉层级和上下文
- 支持手势关闭，用户体验良好

**替代方案：**
- **使用 NavigationLink 推入新页面**：不推荐，登录是临时操作，不应进入导航栈
- **使用 FullScreenCover**：过于强调，可能让用户感到被打断

**实现：**
```swift
.sheet(isPresented: $showQRCode) {
    QRCodeLoginView(viewModel: QRCodeLoginViewModel())
}
```

### 决策 7：登录状态管理使用顶层 ContentView

**选择：** 在 `ContentView` 中使用 `@State` 持有 `AccountManagerIOS`，根据 `isLoggedIn` 状态切换 `LoginView` 和 `MainTabView`。

**理由：**
- 简单直观的状态驱动 UI 模式
- 登录状态变化时自动重新渲染整个应用视图层级
- 避免深层嵌套和复杂的状态传递
- 使用 @Observable 时，@State 可以直接持有引用类型

**替代方案：**
- **使用 @Environment 注入**：可行，但增加一层间接性
- **使用 AppDelegate 管理**：不符合 SwiftUI 的声明式设计

**实现：**
```swift
@main
struct BilibiliLive_iOSApp: App {
    @State private var accountManager = AccountManagerIOS.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(accountManager)
        }
    }
}
```

### 决策 8：二维码生成使用 CoreImage

**选择：** 使用 `CIFilter(name: "CIQRCodeGenerator")` 生成二维码，与 tvOS 实现一致。

**理由：**
- iOS 原生支持，无需第三方库
- 性能良好，质量可控
- 与 tvOS 代码逻辑完全一致，降低维护成本

**替代方案：**
- **使用第三方库（如 EFQRCode）**：增加依赖，收益不大

## 风险 / 权衡

### 风险 1：Timer 在后台可能不可靠
**影响：** 如果用户切换到后台，Timer 可能暂停，导致轮询中断。  
**缓解：** 
- 在 `onAppear` 和 `onDisappear` 中管理 Timer 生命周期
- 用户返回前台时检测二维码是否过期，自动刷新

### 风险 2：账号数据未加密存储
**影响：** Token 和 cookies 存储在 UserDefaults 中，可能被越狱设备访问。  
**缓解：** 
- 当前与 tvOS 保持一致，未来可考虑迁移到 Keychain
- 文档中注明这是已知限制

### 风险 3：iOS 和 tvOS 代码重复
**影响：** 登录逻辑和账号管理在两个平台都有实现，维护成本增加。  
**缓解：** 
- 复用 API 层（ApiRequest）减少重复
- 清晰的代码注释和文档，便于同步更新

### 风险 4：二维码过期处理的用户体验
**影响：** 如果用户长时间不扫码，二维码过期后自动刷新可能让用户困惑。  
**缓解：** 
- 在自动刷新时显示提示信息："二维码已过期，已自动刷新"
- 提供手动刷新按钮作为备选

### 风险 5：网络错误处理不充分
**影响：** 如果 API 请求失败，可能导致界面卡住或无反馈。  
**缓解：** 
- 为所有网络请求添加错误处理
- 在 ViewModel 中维护 `errorMessage` 状态
- 显示友好的错误提示和重试按钮

### 权衡：不支持多账号切换
**决定：** 第一版只实现单账号登录，不提供账号切换界面。  
**理由：** 
- 简化初期实现，优先完成核心登录功能
- tvOS 版本也未暴露多账号切换界面
- 后端数据结构支持多账号，未来可扩展

## 文件结构

```
BilibiliLive-iOS/
├── Models/
│   ├── AccountManagerIOS.swift          # 账号管理（@Observable）
│   └── LoginModels.swift                 # 共享的数据模型（Account, LoginToken 等）
├── ViewModels/
│   └── QRCodeLoginViewModel.swift        # 二维码登录业务逻辑
├── Views/
│   ├── LoginView.swift                   # 登录主界面（已存在，需更新）
│   ├── QRCodeLoginView.swift             # 二维码登录弹窗（已存在，需更新）
│   └── Components/
│       └── QRCodeImageView.swift         # 二维码图像组件（可选）
├── Utilities/
│   └── QRCodeGenerator.swift             # 二维码生成工具
└── BilibiliLive_iOSApp.swift             # App 入口（已存在，需更新）
```

## 实现顺序

1. **创建数据模型** - `LoginModels.swift`（复用 tvOS 的结构）
2. **实现 QRCodeGenerator** - 二维码生成工具类
3. **实现 QRCodeLoginViewModel** - 登录业务逻辑和状态管理
4. **实现 AccountManagerIOS** - 账号管理和持久化
5. **更新 QRCodeLoginView** - 二维码登录界面集成 ViewModel
6. **更新 LoginView** - 连接登录按钮和二维码弹窗
7. **更新 ContentView** - 集成 AccountManager 和登录状态切换
8. **测试和优化** - 边界情况、错误处理、用户体验调优

## 开放问题

1. **是否需要支持深色模式优化？**  
   建议：二维码在深色模式下可能对比度不足，考虑使用白色背景的容器。

2. **是否需要在登录过程中禁用设备休眠？**  
   建议：不需要，用户可以通过触摸屏幕保持唤醒。

3. **账号资料刷新的时机？**  
   建议：登录成功时和应用启动时自动刷新用户资料。
