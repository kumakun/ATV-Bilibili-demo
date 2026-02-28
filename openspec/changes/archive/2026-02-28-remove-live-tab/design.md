## 上下文

当前应用的主导航使用 `BLTabBarViewController`（继承自 `UITabBarController`）管理 7 个标签页。直播功能位于第一个位置（索引 0），但使用频率较低。为了简化主界面并专注于点播视频内容，需要移除直播 Tab。

**当前状态：**
- Tab Bar 包含 7 个标签：直播、推荐、热门、排行榜、关注、收藏、我的
- 直播位于索引 0（最左侧）
- `selectedIndex` 保存在 UserDefaults 中用于恢复用户上次选中的 Tab
- 直播相关代码分布在 `BilibiliLive/Module/Live/` 目录

**约束：**
- 保持其他 6 个 Tab 的功能完全不变
- 保留直播相关的底层代码（播放器、弹幕等）以便将来使用
- 向后兼容：处理已保存的旧 selectedIndex 值

## 目标 / 非目标

**目标：**
- 从主 Tab Bar 中移除"直播"标签及其视图控制器
- 确保剩余 6 个 Tab 正常工作且顺序正确
- 正确处理保存的 Tab 索引（特别是旧的直播 Tab 索引）
- 代码改动最小化，降低引入 bug 的风险

**非目标：**
- 删除直播相关的业务逻辑代码（保留用于未来）
- 修改其他 Tab 的实现或布局
- 添加新的直播入口（留待未来决策）
- 数据迁移或清理（UserDefaults 中的旧数据不影响功能）

## 决策

### 决策 1：保留 Live 模块代码，仅移除 UI 入口

**选择：** 保留 `BilibiliLive/Module/Live/` 目录下的所有代码，只从 `BLTabBarViewController` 中移除 `LiveViewController` 的实例化和添加。

**理由：**
- 直播功能的代码质量良好，重新开发成本高
- 未来可能通过其他入口（搜索、个人中心、推送通知等）访问直播
- 删除后再恢复需要处理 git 历史，不如保留
- LivePlayerViewController、LiveDanMuProvider 等组件可能被其他模块引用

**替代方案（已否决）：**
- **完全删除 Live 模块**：风险高，且未来可能需要恢复
- **使用编译条件隔离**：过度工程化，增加复杂度

### 决策 2：直接移除代码，不使用 Feature Flag

**选择：** 直接从 `viewDidLoad()` 中删除 LiveViewController 相关的 3 行代码。

**理由：**
- 这是一个简单的 UI 变更，不涉及复杂的业务逻辑
- Feature Flag 增加了不必要的复杂度和维护成本
- 如需回滚，直接 git revert 即可
- 不需要 A/B 测试或灰度发布

**替代方案（已否决）：**
- **使用 Feature Flag 控制**：对于简单的 UI 移除过于复杂
- **使用编译时宏**：增加构建配置复杂度

### 决策 3：selectedIndex 处理策略：依赖系统行为

**选择：** 不添加特殊的 selectedIndex 校验逻辑，依赖 UITabBarController 的默认行为。

**理由：**
- UITabBarController 会自动处理超出范围的索引（回退到 0）
- 旧的索引 0（原直播）自动变为新的索引 0（推荐），用户体验连续
- 索引 1-6 自动变为 0-5，映射关系清晰
- 减少额外的边界检查代码

**行为分析：**
```
旧索引 → 新索引 → 显示 Tab
   0   →    0   → 推荐（原直播用户默认看到推荐）
   1   →    0   → 推荐
   2   →    1   → 热门
   3   →    2   → 排行榜
   4   →    3   → 关注
   5   →    4   → 收藏
   6   →    5   → 我的
  >6   →    0   → 推荐（系统自动处理）
```

**替代方案（已否决）：**
- **显式校验和重置索引**：增加代码复杂度，且系统已有保护机制
- **清空 UserDefaults**：丢失用户偏好，体验不好

### 决策 4：不修改 selectedIndexKey 常量

**选择：** 保持 `selectedIndexKey = "BLTabBarViewController.selectedIndex"` 不变。

**理由：**
- UserDefaults 中保存的值仍然有效（只是映射关系变了）
- 不需要数据迁移
- 保持代码一致性

## 风险 / 权衡

### 风险 1：用户对移除直播功能的负面反馈

**风险：** 依赖直播功能的用户可能投诉或流失。

**缓解措施：**
- 保留代码以便快速恢复
- 监控用户反馈和留存数据
- 准备好通过其他入口（如"我的"页面）快速添加直播入口

### 风险 2：索引映射导致的用户体验问题

**风险：** 用户之前选中"热门"（索引 2），更新后可能看到"热门"（现在是索引 1）或"排行榜"（现在是索引 2）。

**影响分析：** 
- 实际上，UserDefaults 保存的是索引值，不是 Tab 名称
- 如果用户之前选中"热门"（旧索引 2），更新后会显示"排行榜"（新索引 2）
- 这是一次性的轻微错位，用户重新选择后即恢复正常

**缓解措施：**
- 接受这个轻微的一次性体验问题（影响范围小）
- 或者在 AppDelegate 中检测版本变更时清空 selectedIndex（需权衡）

### 风险 3：代码中对 Tab 索引的硬编码引用

**风险：** 项目其他地方可能硬编码了 Tab 索引（如 `selectedIndex = 2` 跳转到某个 Tab）。

**缓解措施：**
- 在实施前搜索 `selectedIndex` 的所有使用位置
- 如发现硬编码，更新为相对引用或常量

### 权衡：保留代码 vs 清理代码

**选择：** 保留 Live 模块代码

**权衡：**
- ✅ 优点：快速恢复能力、代码复用性
- ❌ 缺点：增加项目体积（约 5-10 个文件）、潜在的无用代码

**判断：** 优点大于缺点，特别是考虑到未来可能需要直播功能。

## 实现方法

### 步骤 1：修改 BLTabBarViewController.swift

在 `viewDidLoad()` 方法中：

**移除以下代码：**
```swift
let liveVC = LiveViewController()
liveVC.tabBarItem.title = "直播"
vcs.append(liveVC)
```

**保持其余代码不变**，包括：
- 推荐、热门、排行榜、关注、收藏、我的的初始化和添加
- `setViewControllers(vcs, animated: false)`
- `selectedIndex` 的读取和设置

### 步骤 2：验证 LiveViewController 的引用

**检查：** 确保 `LiveViewController` 仅在 `BLTabBarViewController` 中被引用。

**方法：** 在项目中搜索 `LiveViewController` 的使用位置。

**如果发现其他引用：** 评估是否需要保留或移除。

### 步骤 3：测试

**测试场景：**
1. **新用户首次启动**：验证显示 6 个 Tab，默认选中"推荐"
2. **旧用户更新后启动**：验证根据保存的索引正确显示 Tab
3. **切换 Tab**：验证所有 6 个 Tab 可正常切换和交互
4. **PlayPause 按键**：验证遥控器 PlayPause 键的刷新功能仍正常

## 回滚计划

**如需回滚（恢复直播 Tab）：**

1. **Git Revert**：执行 `git revert <commit-hash>` 恢复代码
2. **或手动恢复**：在 `BLTabBarViewController.viewDidLoad()` 中重新添加 3 行代码：
   ```swift
   let liveVC = LiveViewController()
   liveVC.tabBarItem.title = "直播"
   vcs.append(liveVC)
   ```
   确保添加在 `var vcs = [UIViewController]()` 之后、第一个位置

**回滚风险：** 极低，因为只是恢复 UI 入口，底层代码从未删除。
