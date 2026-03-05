## 为什么

目前项目已经建立了 iOS 平台的基础框架（`BilibiliLive-iOS` target），但登录功能仅有占位界面，缺少真实的二维码扫码登录和账号管理集成。用户无法在 iOS 设备上通过哔哩哔哩账号登录，限制了应用的核心功能使用。现在需要参考 tvOS 平台的成熟登录实现，为 iOS 平台使用 SwiftUI 构建独立的、功能完整的登录系统。

## 变更内容

- **新增**：为 iOS 平台实现完整的二维码扫码登录流程，包括：
  - 二维码生成和刷新机制
  - 轮询验证登录状态
  - 登录成功后的令牌和 Cookie 处理
- **新增**：为 iOS 平台创建独立的账号管理模块（SwiftUI 适配）
- **新增**：Cookie 存储和会话管理（iOS 平台独立实现）
- **修改**：完善现有的 `LoginView.swift` 和 `QRCodeLoginView`，从占位界面升级为功能完整的登录视图
- **修改**：集成登录状态到 iOS 应用的主导航流程中

**注意**：iOS 平台将编写独立代码，不与 tvOS 平台共享实现，但遵循相同的 API 接口和业务逻辑。

## 功能 (Capabilities)

### 新增功能

- `ios-qrcode-login`: iOS 平台的二维码扫码登录功能，包括二维码生成、展示、刷新和轮询验证
- `ios-account-management`: iOS 平台的账号管理功能，包括用户令牌存储、Cookie 管理、登录状态维护和账号信息获取

### 修改功能

无（iOS 平台是新实现，不涉及现有规范的修改）

## 影响

**受影响的代码：**
- `BilibiliLive-iOS/LoginView.swift` - 升级为功能完整的登录界面
- `BilibiliLive-iOS/` - 新增账号管理相关的 Swift 文件（SwiftUI 架构）

**依赖的现有模块：**
- `BilibiliLive/Request/ApiRequest.swift` - 复用登录相关的 API 请求方法（`requestLoginQR`, `verifyLoginQR`）
- `BilibiliLive/Request/CookieManager.swift` - 参考 Cookie 管理逻辑（iOS 平台独立实现）

**API 依赖：**
- 哔哩哔哩登录 API（二维码生成和验证接口）

**用户体验影响：**
- iOS 用户将能够通过官方客户端扫码登录
- 登录成功后，应用可以访问需要认证的功能（个人中心、收藏、关注等）
- 登录状态将在应用重启后持久化保存
