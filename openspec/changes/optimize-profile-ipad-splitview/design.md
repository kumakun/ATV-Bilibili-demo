## 上下文

当前 iOS 个人中心页面（ProfileView）采用 NavigationStack + ScrollView 的单栏布局，适合 iPhone 竖屏使用。页面包含三个主要部分：
1. 用户信息卡片（UserInfoCard）：显示头像、用户名、签名和二维码入口
2. 统计数据卡片（UserStatsView）：显示关注、粉丝、获赞三个数值
3. 功能列表（FunctionListSection）：关注UP、追番追剧、历史记录等功能入口

在 iPad 上，这种竖向滚动的单栏布局没有充分利用横向空间，用户需要反复进入和退出功能页面，效率较低。此外，统计数据占据了独立的卡片区域，但信息价值相对有限。

**技术背景**：
- 使用 SwiftUI + @Observable 框架
- ProfileViewModel 负责数据管理和业务逻辑
- 支持账号切换和自动刷新
- 现有代码为 iOS 项目独立实现，不与 tvOS 共享

## 目标 / 非目标

**目标：**
1. 在 iPad 上实现 NavigationSplitView 交互，提供侧边栏（sidebar）+ 详情页（detail）的双栏布局
2. 移除"关注 粉丝 获赞"统计数据的展示，简化页面结构
3. 保持 iPhone 上现有的 NavigationStack 交互方式不变
4. 功能列表项在 iPad 侧边栏中展示，点击后右侧显示对应内容
5. 保持用户信息卡片的展示和交互

**非目标：**
1. 不修改各个功能详情页（FollowUpsView、FollowBangumiView 等）的内部实现
2. 不改变 ProfileViewModel 的数据加载逻辑（除移除统计数据相关属性外）
3. 不涉及账号管理、登录登出的核心逻辑修改
4. 不重新设计功能列表的图标和顺序

## 决策

### 决策 1: 使用 NavigationSplitView + 设备检测实现响应式布局

**选择方案**：使用 SwiftUI 的 `NavigationSplitView` 组件，根据 `UIDevice.current.userInterfaceIdiom` 判断设备类型，iPad 使用 SplitView，iPhone 使用 NavigationStack。

**理由**：
- `NavigationSplitView` 是 SwiftUI 原生提供的双栏/三栏布局组件，适合 iPad 的 master-detail 交互模式
- 可以自动处理侧边栏的展开/收起、拖拽调整等系统级交互
- 相比自定义 HStack + 状态管理，代码更简洁、维护成本更低

**替代方案**：
- 使用 `HStack` + `@State` 手动管理侧边栏显示状态：需要自己实现选中状态、过渡动画，代码复杂度高
- 使用第三方库（如 SwiftUI-Sidebar）：引入外部依赖，不如使用原生组件稳定

**实现细节**：
```swift
// iPad 使用 NavigationSplitView
NavigationSplitView {
  // Sidebar: 用户信息 + 功能列表
} detail: {
  // Detail: 对应的功能详情页
}

// iPhone 使用 NavigationStack
NavigationStack {
  ScrollView {
    // 现有布局
  }
}
```

### 决策 2: 移除 UserStatsView 组件及 ViewModel 中的统计数据属性

**选择方案**：直接删除 `UserStatsView` 和 `StatItem` 组件，从 ProfileViewModel 中移除 `followingCount`、`followerCount`、`likesCount` 属性及相关的 `UserProfile.following/follower/likes` 字段。

**理由**：
- 统计数据在个人中心页面的使用频率低，占用了宝贵的垂直空间
- 移除后页面更简洁，用户注意力集中在核心功能上
- 减少 ViewModel 的属性和格式化逻辑，降低维护成本

**替代方案**：
- 保留统计数据但缩小展示：仍然占用空间，且数据价值不高
- 将统计数据移到用户信息卡片内：会让卡片过于拥挤

### 决策 3: 侧边栏显示用户信息卡片 + 功能列表

**选择方案**：在 iPad 的侧边栏中，顶部显示用户信息卡片（UserInfoCard），下方显示功能列表（使用 List 组件）。

**理由**：
- 用户信息卡片作为个人中心的核心信息，应该在侧边栏中持续可见
- 使用 `List` 组件替代 `VStack` 可以更好地利用侧边栏空间，支持滚动和选中状态
- 侧边栏宽度适中（约 320pt），可以容纳用户信息和功能列表

**实现细节**：
```swift
// Sidebar 结构
VStack(spacing: 0) {
  UserInfoCard(viewModel: viewModel)
    .padding()
  
  List(selection: $selectedRoute) {
    ForEach(功能路由) { route in
      NavigationLink(value: route) {
        Label(route.title, systemImage: route.icon)
      }
    }
  }
}
```

### 决策 4: 使用 @State 管理选中的功能路由

**选择方案**：在 ProfileView 中添加 `@State private var selectedRoute: ProfileRoute?` 状态，绑定到 `NavigationSplitView` 的 `selection` 参数。

**理由**：
- NavigationSplitView 需要通过 selection 参数追踪当前选中的项
- 使用 @State 可以响应式地更新详情页内容
- 支持深度链接和状态恢复

### 决策 5: 保持 ProfileRoute 枚举不变

**选择方案**：继续使用现有的 `ProfileRoute` 枚举作为导航路由定义，不做修改。

**理由**：
- 现有路由定义已经涵盖所有功能页面
- iPhone 和 iPad 共用同一套路由定义，减少重复代码
- 功能列表的顺序和内容保持一致

## 风险 / 权衡

### 风险 1: 移除统计数据后用户可能找不到这些信息

**缓解措施**：
- 统计数据在 B站 的主要价值在于内容创作者，普通用户查看频率极低
- 如果后续需要，可以在账号切换页或设置页中添加统计数据入口
- 本次变更聚焦在优化 iPad 体验，iPhone 用户的使用习惯不受影响

### 风险 2: NavigationSplitView 在不同 iPad 尺寸上的表现差异

**缓解措施**：
- NavigationSplitView 会根据可用空间自动调整侧边栏宽度
- 在小屏 iPad（如 iPad mini）上，侧边栏可以自动收起为 overlay 模式
- 测试时需要覆盖不同尺寸的 iPad 设备和横竖屏方向

### 风险 3: 功能列表项的高度和间距在 List 中的表现可能与原设计不同

**缓解措施**：
- 使用 `.listStyle(.sidebar)` 确保外观符合 iPad 侧边栏标准
- 如果需要，可以通过 `.listRowInsets()` 和 `.listRowBackground()` 自定义样式
- 保持图标、文字和颜色配置不变，只调整布局容器

### 权衡 1: 代码复杂度略有增加（设备判断和两套布局）

**权衡理由**：
- 增加的代码量有限（约 50-80 行），可维护性可接受
- 通过合理的视图拆分（如 ProfileSidebarContent、ProfileDetailContent），可以保持代码清晰
- 收益是 iPad 用户体验的显著提升，值得这点额外复杂度

### 权衡 2: 功能列表在 iPhone 和 iPad 上的交互方式不同

**权衡理由**：
- 这是符合平台规范的设计，用户已经习惯不同设备上的不同交互模式
- iPhone 的 push 导航和 iPad 的 split view 都是各自平台的最佳实践
- 通过共享 ProfileRoute 和详情页 View，保持了逻辑一致性

## 迁移计划

1. **第一步**：移除 UserStatsView 组件
   - 从 ProfileView 中删除 UserStatsView 的引用
   - 删除 UserStatsView 和 StatItem 的定义
   - 从 ProfileViewModel 中移除 followingCount、followerCount、likesCount 属性
   - 编译验证，确保没有其他地方依赖这些组件

2. **第二步**：实现设备判断和条件布局
   - 在 ProfileView 中添加设备类型检测逻辑
   - 使用 `if UIDevice.current.userInterfaceIdiom == .pad` 分支创建不同的布局
   - iPhone 保持现有 NavigationStack 结构
   - iPad 使用新的 NavigationSplitView 结构

3. **第三步**：实现 iPad 的 NavigationSplitView 布局
   - 创建侧边栏内容：UserInfoCard + List<ProfileRoute>
   - 创建详情页内容：根据 selectedRoute 显示对应的功能页面
   - 处理登出确认对话框和错误提示

4. **第四步**：测试和调优
   - 在 iPhone（不同尺寸）和 iPad（不同尺寸、横竖屏）上测试
   - 验证账号切换、登出、刷新等功能正常
   - 检查深度链接和状态恢复是否工作
   - 调整侧边栏宽度、间距、颜色等视觉细节

**回滚策略**：
- 如果遇到严重问题，可以保留移除 UserStatsView 的变更，仅回滚 NavigationSplitView 部分
- Git 分支策略：在独立分支开发，测试通过后合并到主分支

## 开放问题

1. **侧边栏宽度**：NavigationSplitView 的侧边栏默认宽度是否合适？是否需要自定义？
   - 建议先使用默认宽度，根据实际效果调整

2. **首次进入时的默认选中项**：iPad 首次打开个人中心时，右侧是显示空白、显示"请选择功能"提示，还是默认选中第一个功能？
   - 建议默认不选中任何功能，显示"请选择左侧功能"的占位视图

3. **登出按钮位置**：登出按钮是放在功能列表的最后，还是放在侧边栏的底部固定位置？
   - 建议保持在列表最后，与 iPhone 保持一致
