## 1. 前期准备

- [x] 1.1 提交所有当前更改，确保工作目录干净
- [x] 1.2 搜索整个代码库，检查是否有其他文件引用即将删除的类（LiveViewController、FeedViewController、HotViewController、RankingViewController）
- [x] 1.3 检查 Storyboard 文件中是否有对这些 ViewController 的引用
- [x] 1.4 检查 Feed 组件（StandardVideoCollectionViewController、FeedCollectionViewController）是否被其他功能使用

## 2. 删除直播模块

- [x] 2.1 删除 `BilibiliLive/Module/Live/BrotliDecompressor.swift`
- [x] 2.2 删除 `BilibiliLive/Module/Live/LiveDanMuProvider.swift`
- [x] 2.3 删除 `BilibiliLive/Module/Live/LivePlayerViewController.swift`
- [x] 2.4 删除 `BilibiliLive/Module/Live/LivePlayerViewModel.swift`
- [x] 2.5 删除 `BilibiliLive/Module/Live/LiveViewController.swift`
- [x] 2.6 删除 `BilibiliLive/Module/Live/` 目录（如果为空）

## 3. 删除废弃的 ViewController

- [x] 3.1 删除 `BilibiliLive/Module/ViewController/FeedViewController.swift`
- [x] 3.2 删除 `BilibiliLive/Module/ViewController/HotViewController.swift`
- [x] 3.3 删除 `BilibiliLive/Module/ViewController/RankingViewController.swift`

## 4. 更新 Xcode 项目文件

- [ ] 4.1 在 Xcode 中打开项目，验证项目导航器中已删除的文件显示为红色（缺失）
- [ ] 4.2 在 Xcode 中移除对已删除文件的引用（右键点击红色文件 → Delete → Remove Reference）
- [ ] 4.3 清理 Xcode 构建缓存（Product → Clean Build Folder）

## 5. 验证和测试

- [x] 5.1 构建项目，确保没有编译错误
- [x] 5.2 运行应用，验证主 Tab Bar 仍正确显示 3 个标签页
- [x] 5.3 测试索引映射逻辑：清除应用数据后重装，验证默认显示"关注" Tab
- [x] 5.4 搜索代码库中是否有任何残留的 import 或引用

## 6. 归档规范

- [ ] 6.1 运行 `openspec-cn archive --change remove-feed-hot-ranking-modules` 将增量规范归档到主规范
- [ ] 6.2 验证 `openspec/specs/main-navigation/spec.md` 已更新为 3 标签页结构
- [ ] 6.3 提交所有更改，包含描述性的 commit message
