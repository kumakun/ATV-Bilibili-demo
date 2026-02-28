## 1. 移除 IBOutlet 和数据模型属性

- [x] 1.1 移除 `recommandCollectionView` 的 IBOutlet 声明
- [x] 1.2 移除 `replysCollectionView` 的 IBOutlet 声明
- [x] 1.3 移除 `repliesCollectionViewHeightConstraints` 的 IBOutlet 声明
- [x] 1.4 移除 `replys: Replys?` 私有属性

## 2. 移除网络请求相关代码

- [x] 2.1 在 `fetchData()` 方法中移除 `WebRequest.requestReplys(aid:)` 调用及其闭包
- [x] 2.2 检查并移除其他推荐视频相关的网络请求代码（如果有）
- [x] 2.3 在 `fetchData()` 方法中移除番剧相关的推荐视图隐藏逻辑

## 3. 移除 Combine 订阅

- [x] 3.1 在 `viewDidLoad()` 中移除 `replysCollectionView.publisher(for: \.contentSize)` 订阅

## 4. 清理 UICollectionView DataSource 方法

- [x] 4.1 在 `collectionView(_:numberOfItemsInSection:)` 中移除 `replysCollectionView` 和 `recommandCollectionView` 的 case 分支
- [x] 4.2 在 `collectionView(_:cellForItemAt:)` 中移除 `replysCollectionView` 和 `recommandCollectionView` 的 case 分支
- [x] 4.3 在 `collectionView(_:didSelectItemAt:)` 中移除 `replysCollectionView` 和 `recommandCollectionView` 的 case 分支

## 5. 清理 UI 更新逻辑

- [x] 5.1 在 `update(with:)` 方法中移除 `recommandCollectionView.superview?.isHidden` 的设置
- [x] 5.2 在 `update(with:)` 方法中移除 `recommandCollectionView.reloadData()` 调用

## 6. 验证和测试

- [x] 6.1 编译项目，确保没有编译错误
- [x] 6.2 运行应用，打开视频详情页，验证页面正常显示
- [x] 6.3 测试播放功能是否正常
- [x] 6.4 测试点赞、投币、收藏等互动功能
- [x] 6.5 测试分P列表切换功能（多P视频）
- [x] 6.6 测试合集列表功能
- [x] 6.7 测试 tvOS 焦点导航是否流畅
- [x] 6.8 确认不再发起推荐和评论的网络请求
