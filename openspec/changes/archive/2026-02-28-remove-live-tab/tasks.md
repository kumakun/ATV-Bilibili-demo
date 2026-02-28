## 1. 准备工作

- [x] 1.1 在项目中搜索 `LiveViewController` 的所有引用，确认只在 `BLTabBarViewController` 中使用
- [x] 1.2 在项目中搜索 `selectedIndex` 的所有使用位置，检查是否有硬编码的索引值引用
- [x] 1.3 确认当前 git 分支干净，创建新的功能分支 `remove-live-tab`

## 2. 代码修改

- [x] 2.1 打开 `BilibiliLive/BLTabBarViewController.swift` 文件
- [x] 2.2 在 `viewDidLoad()` 方法中删除以下 3 行代码：
  - `let liveVC = LiveViewController()`
  - `liveVC.tabBarItem.title = "直播"`
  - `vcs.append(liveVC)`
- [x] 2.3 验证删除后剩余 6 个 ViewController 的添加顺序正确（推荐、热门、排行榜、关注、收藏、我的）
- [x] 2.4 保存文件并编译，确保没有编译错误

## 3. 测试验证

- [ ] 3.1 在模拟器或真机上启动应用，验证 Tab Bar 显示恰好 6 个标签
- [ ] 3.2 验证 6 个 Tab 的顺序正确：推荐、热门、排行榜、关注、收藏、我的
- [ ] 3.3 验证"直播" Tab 不再显示
- [ ] 3.4 逐个点击所有 6 个 Tab，确认每个 Tab 都能正常打开和显示内容
- [ ] 3.5 测试 Tab 切换后再次启动应用，验证能正确恢复到上次选中的 Tab
- [ ] 3.6 清除应用数据（或手动设置 UserDefaults 中的 selectedIndex），测试首次启动默认显示"推荐" Tab

## 4. 边界测试

- [ ] 4.1 手动设置 UserDefaults 中的 selectedIndex 为 0，验证启动后显示"推荐" Tab
- [ ] 4.2 手动设置 UserDefaults 中的 selectedIndex 为 6（超出范围），验证应用不崩溃且显示合理的 Tab
- [ ] 4.3 在不同 Tab 之间快速切换，验证没有 UI 闪烁或异常
- [ ] 4.4 测试遥控器 PlayPause 键在各个 Tab 中的刷新功能是否正常

## 5. 代码审查与清理

- [ ] 5.1 运行 SwiftFormat（如果项目有配置），确保代码格式符合规范
- [ ] 5.2 检查是否有未使用的 import 语句需要清理
- [x] 5.3 提交代码，commit message 使用：`feat: 移除主 Tab Bar 中的直播标签`
- [ ] 5.4 推送到远程仓库并创建 Pull Request（如果团队协作）

## 6. 文档与沟通

- [x] 6.1 更新 README.md 中的功能列表（如果有提到直播 Tab）
- [ ] 6.2 如有需要，准备发布说明或更新日志，说明此变更
- [ ] 6.3 通知团队成员此变更，特别是 QA 团队进行回归测试
