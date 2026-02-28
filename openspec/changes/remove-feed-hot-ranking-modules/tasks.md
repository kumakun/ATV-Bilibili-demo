## 1. 前期准备

- [ ] 1.1 提交所有当前更改，确保工作目录干净
- [ ] 1.2 搜索整个代码库，检查是否有其他文件引用即将删除的类（LiveViewController、FeedViewController、HotViewController、RankingViewController）
- [ ] 1.3 检查 Storyboard 文件中是否有对这些 ViewController 的引用
- [ ] 1.4 检查 Feed 组件（StandardVideoCollectionViewController、FeedCollectionViewController）是否被其他功能使用

## 2. 删除直播模块

- [ ] 2.1 删除 `BilibiliLive/Module/Live/BrotliDecompressor.swift`
- [ ] 2.2 删除 `BilibiliLive/Module/Live/LiveDanMuProvider.swift`
- [ ] 2.3 删除 `BilibiliLive/Module/Live/LivePlayerViewController.swift`
- [ ] 2.4 删除 `BilibiliLive/Module/Live/LivePlayerViewModel.swift`
- [ ] 2.5 删除 `BilibiliLive/Module/Live/LiveViewController.swift`
- [ ] 2.6 删除 `BilibiliLive/Module/Live/` 目录（如果为空）

## 3. 删除 Feed 组件

- [ ] 3.1 删除 `BilibiliLive/Component/Feed/FeedCollectionViewCell.swift`
- [ ] 3.2 删除 `BilibiliLive/Component/Feed/FeedCollectionViewController.swift`
- [ ] 3.3 删除 `BilibiliLive/Component/Feed/StandardVideoCollectionViewController.swift`
- [ ] 3.4 删除 `BilibiliLive/Component/Feed/TitleSupplementaryView.swift`
- [ ] 3.5 删除 `BilibiliLive/Component/Feed/` 目录（如果为空）

## 4. 删除废弃的 ViewController

- [ ] 4.1 删除 `BilibiliLive/Module/ViewController/FeedViewController.swift`
- [ ] 4.2 删除 `BilibiliLive/Module/ViewController/HotViewController.swift`
- [ ] 4.3 删除 `BilibiliLive/Module/ViewController/RankingViewController.swift`

## 5. 更新 Xcode 项目文件

- [ ] 5.1 在 Xcode 中打开项目，验证项目导航器中已删除的文件显示为红色（缺失）
- [ ] 5.2 在 Xcode 中移除对已删除文件的引用（右键点击红色文件 → Delete → Remove Reference）
- [ ] 5.3 清理 Xcode 构建缓存（Product → Clean Build Folder）

## 6. 验证和测试

- [ ] 6.1 构建项目，确保没有编译错误
- [ ] 6.2 运行应用，验证主 Tab Bar 仍正确显示 3 个标签页
- [ ] 6.3 测试索引映射逻辑：清除应用数据后重装，验证默认显示"关注" Tab
- [ ] 6.4 搜索代码库中是否有任何残留的 import 或引用

## 7. 归档规范

- [ ] 7.1 运行 `openspec-cn archive --change remove-feed-hot-ranking-modules` 将增量规范归档到主规范
- [ ] 7.2 验证 `openspec/specs/main-navigation/spec.md` 已更新为 3 标签页结构
- [ ] 7.3 提交所有更改，包含描述性的 commit message
