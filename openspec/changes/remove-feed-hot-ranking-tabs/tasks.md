## 1. 代码修改

- [x] 1.1 在 BLTabBarViewController.swift 中删除创建 FeedViewController 的代码（约 3 行）
- [x] 1.2 在 BLTabBarViewController.swift 中删除创建 HotViewController 的代码（约 3 行）
- [x] 1.3 在 BLTabBarViewController.swift 中删除创建 RankingViewController 的代码（约 3 行）
- [x] 1.4 在 BLTabBarViewController.swift 中添加 selectedIndex 映射逻辑以处理旧索引值

## 2. 验证与测试

- [x] 2.1 编译项目，确保无编译错误或警告
- [ ] 2.2 冷启动应用，验证主 Tab Bar 显示恰好 3 个标签（关注、收藏、我的）
- [ ] 2.3 验证 Tab 顺序正确：关注（索引0）、收藏（索引1）、我的（索引2）
- [ ] 2.4 手动修改 UserDefaults 中的 selectedIndex 为 0，启动应用，验证显示"关注" Tab
- [ ] 2.5 手动修改 UserDefaults 中的 selectedIndex 为 3，启动应用，验证映射到"关注" Tab（新索引0）
- [ ] 2.6 手动修改 UserDefaults 中的 selectedIndex 为 4，启动应用，验证映射到"收藏" Tab（新索引1）
- [ ] 2.7 手动修改 UserDefaults 中的 selectedIndex 为 5，启动应用，验证映射到"我的" Tab（新索引2）
- [ ] 2.8 手动修改 UserDefaults 中的 selectedIndex 为无效值（如 -1, 999），启动应用，验证 fallback 到"关注" Tab
- [ ] 2.9 测试 Tab 切换功能，验证各 Tab 内容正常加载和显示
- [ ] 2.10 验证"关注"、"收藏"、"我的"三个功能完全不受影响，正常工作

## 3. 文档更新

- [x] 3.1 检查 README.md 是否包含推荐/热门/排行榜功能的描述，如有则更新或移除相关说明
- [ ] 3.2 更新项目文档（如有）说明主导航变更

## 4. 完成清理

- [x] 4.1 提交代码变更到 git，commit message 说明变更内容
- [ ] 4.2 运行 `openspec-cn archive remove-feed-hot-ranking-tabs` 归档变更
- [ ] 4.3 同步 specs 到 openspec/specs/ 目录
