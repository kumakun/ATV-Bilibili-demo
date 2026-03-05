## 1. 移除统计数据相关代码

- [x] 1.1 从 ProfileView.swift 中删除 UserStatsView 的引用和调用
- [x] 1.2 删除 UserStatsView 和 StatItem 组件的定义代码
- [x] 1.3 从 ProfileViewModel.swift 中移除 followingCount、followerCount、likesCount 属性
- [x] 1.4 从 ProfileViewModel.swift 中移除 formatCount 方法（如果仅用于统计数据格式化）
- [x] 1.5 从 UserProfile 数据模型中移除 following、follower、likes 字段
- [x] 1.6 编译验证，确保没有其他地方依赖这些已删除的组件和属性

## 2. 添加设备检测逻辑

- [x] 2.1 在 ProfileView 中添加设备类型检测的计算属性（使用 UIDevice.current.userInterfaceIdiom）
- [x] 2.2 创建条件编译逻辑，根据设备类型返回不同的视图结构

## 3. 实现 iPad NavigationSplitView 布局

- [x] 3.1 创建 iPad 专用的 NavigationSplitView 主结构
- [x] 3.2 添加 @State 变量管理选中的功能路由（selectedRoute: ProfileRoute?）
- [x] 3.3 实现侧边栏内容：创建包含 UserInfoCard 和功能列表的 VStack 结构
- [x] 3.4 将功能列表改用 List 组件，使用 NavigationLink 实现功能项
- [x] 3.5 配置 List 的样式为 .sidebar 模式
- [x] 3.6 为每个功能项配置图标、标题和颜色（保持与现有设计一致）

## 4. 实现详情页区域

- [x] 4.1 创建详情页的 switch 结构，根据 selectedRoute 显示对应的功能视图
- [x] 4.2 添加未选中状态的占位视图（显示"请选择左侧功能"提示）
- [x] 4.3 确保详情页支持各功能视图的独立导航（如视频详情页的 push）

## 5. 处理特殊功能交互

- [x] 5.1 实现"账号切换"功能：点击时以模态方式显示 AccountSwitcherView
- [x] 5.2 实现"登出"功能：点击时显示确认对话框
- [x] 5.3 确保登出确认对话框在 iPad SplitView 布局中正确显示
- [x] 5.4 处理账号切换后的状态更新（清除 selectedRoute，刷新用户信息）

## 6. 保持 iPhone 布局不变

- [x] 6.1 确保 iPhone 设备继续使用现有的 NavigationStack 布局
- [x] 6.2 在 iPhone 布局中移除 UserStatsView 的引用
- [x] 6.3 保持 iPhone 的 push 导航和功能列表交互方式

## 7. 状态管理和生命周期

- [x] 7.1 确保 task 和 refreshable 修饰符在两种布局下都正常工作
- [x] 7.2 处理账号切换时的 onChange 回调，更新用户信息和清除选中状态
- [ ] 7.3 测试从其他 Tab 切换回来时，iPad 侧边栏选中状态的保持

## 8. 样式和视觉调优

- [x] 8.1 调整侧边栏中 UserInfoCard 的 padding 和间距
- [x] 8.2 配置 NavigationSplitView 的侧边栏宽度（如需自定义）
- [x] 8.3 确保功能列表项的高度、间距和选中样式符合设计要求
- [ ] 8.4 测试横竖屏切换时的布局表现

## 9. 测试和验证

- [ ] 9.1 在 iPhone（不同尺寸）上测试：验证移除统计数据后的布局和功能正常
- [ ] 9.2 在 iPad（不同尺寸）上测试：验证 SplitView 布局和侧边栏交互正常
- [ ] 9.3 测试 iPad 横竖屏切换：验证侧边栏自动收起和展开
- [ ] 9.4 测试功能导航：验证每个功能项点击后正确显示详情页
- [ ] 9.5 测试账号切换：验证切换后侧边栏用户信息更新，选中状态清除
- [ ] 9.6 测试登出功能：验证确认对话框显示和登出操作正常
- [ ] 9.7 测试状态保持：验证切换 Tab 后返回时的状态保持
- [ ] 9.8 测试小屏 iPad（iPad mini）：验证侧边栏 overlay 模式正常工作

## 10. 代码清理和文档

- [x] 10.1 移除未使用的代码和注释
- [x] 10.2 确保代码格式符合项目规范
- [x] 10.3 添加必要的代码注释，说明设备检测和布局切换逻辑
- [ ] 10.4 更新相关文档（如有）
