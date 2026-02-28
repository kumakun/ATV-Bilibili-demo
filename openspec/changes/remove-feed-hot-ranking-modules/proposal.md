## 为什么

之前已从主导航中移除了直播、推荐、热门、排行榜功能，现在需要清理这些模块对应的代码文件，以保持代码库的整洁和维护性。这些未使用的代码文件会增加代码库的复杂度和维护成本。

## 变更内容

删除以下模块的所有相关代码文件：
- **直播模块**：删除 `BilibiliLive/Module/Live/` 目录及其所有文件
- **推荐模块**：删除 `BilibiliLive/Module/ViewController/FeedViewController.swift`
- **热门模块**：删除 `BilibiliLive/Module/ViewController/HotViewController.swift`
- **排行榜模块**：删除 `BilibiliLive/Module/ViewController/RankingViewController.swift`
- **Feed 组件**：删除 `BilibiliLive/Component/Feed/` 目录及其所有文件

保留以下核心功能：
- 关注（FollowsViewController）
- 收藏（FavoriteViewController）
- 我的（PersonalViewController）

## 功能 (Capabilities)

### 新增功能
<!-- 无新增功能 -->

### 修改功能
- `main-navigation`: 更新主导航规范，从描述 6 个标签页（推荐、热门、排行榜、关注、收藏、我的）改为描述当前实际的 3 个标签页（关注、收藏、我的）

## 影响

**受影响的代码和文件**：
- `BilibiliLive/Module/Live/` - 完整目录及其所有文件将被删除
- `BilibiliLive/Module/ViewController/FeedViewController.swift` - 将被删除
- `BilibiliLive/Module/ViewController/HotViewController.swift` - 将被删除
- `BilibiliLive/Module/ViewController/RankingViewController.swift` - 将被删除
- `BilibiliLive/Component/Feed/` - 完整目录及其所有文件将被删除
- `openspec/specs/main-navigation/spec.md` - 需要更新以反映新的 3 标签页结构
- `BilibiliLive/BLTabBarViewController.swift` - 已包含处理旧索引的兼容逻辑，不需要修改

**依赖和系统**：
- 删除的代码可能包含对其他模块的引用，需要确保没有其他地方引用这些被删除的文件
- Xcode 项目文件（.pbxproj）需要相应更新以移除对已删除文件的引用

**破坏性变更**：
- **BREAKING**：无法恢复直播、推荐、热门、排行榜功能，除非恢复代码
