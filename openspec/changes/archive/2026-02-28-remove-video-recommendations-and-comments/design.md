## 上下文

视频详情页 `VideoDetailViewController` 当前包含多个 collection views 来展示不同的内容区域：
- `pageCollectionView` - 展示分P列表
- `ugcCollectionView` - 展示合集内容
- `recommandCollectionView` - 展示推荐视频（需移除）
- `replysCollectionView` - 展示热门评论（需移除）

当前架构使用标准的 UIKit collection view 模式，通过 delegate 和 dataSource 处理数据和用户交互。页面使用 storyboard (Main.storyboard) 进行界面布局。

**约束**：
- tvOS 应用，使用 UIKit 框架
- 需要保持其他功能完整性（播放、点赞、投币、收藏、UP主信息等）
- 移除过程需要清理相关的网络请求、数据模型和 UI 组件

## 目标 / 非目标

**目标：**
- 从 VideoDetailViewController 完全移除推荐视频相关的 UI 和逻辑
- 从 VideoDetailViewController 完全移除评论相关的 UI 和逻辑
- 清理不再使用的网络请求和数据模型属性
- 保持代码整洁，移除所有死代码
- 确保其他功能（分P、合集、播放、互动按钮）正常工作

**非目标：**
- 不修改播放器功能
- 不修改其他页面的推荐或评论功能
- 不添加新的导航方式来替代推荐视频
- 不创建独立的评论页面

## 决策

### 决策 1: 完全移除 vs 隐藏组件

**选择：完全移除**

**理由：**
- 减少代码复杂度和维护负担
- 避免不必要的网络请求和数据处理
- 符合规范要求（禁止展示这些内容）
- 清理死代码，提高代码质量

**替代方案考虑：**
- 隐藏 UI 但保留代码：会留下死代码，增加维护负担，且仍会发起无用的网络请求
- 添加开关控制：增加复杂度，与简化界面的目标不符

### 决策 2: 移除相关的 Cell 类型

**选择：保留 RelatedVideoCell，移除对 ReplyCell 的引用**

**理由：**
- `RelatedVideoCell` 仍被 `ugcCollectionView` 使用（展示合集内容）
- `ReplyCell` 仅用于评论展示，可以安全移除引用
- 避免破坏合集功能

**实现细节：**
- 从 `replysCollectionView` 的数据源方法中移除 `ReplyCell` 引用
- 移除整个 `replysCollectionView` 及其相关代码

### 决策 3: Storyboard 清理

**选择：保留 storyboard 引用，仅通过代码移除功能**

**理由：**
- 避免大规模修改 storyboard 可能引入的布局问题
- 通过设置 `isHidden = true` 或移除 outlet 连接来隐藏不需要的视图
- 保持最小化改动原则

**实现：**
- 移除 `recommandCollectionView` 和 `replysCollectionView` 的 IBOutlet 声明
- 在 `fetchData()` 中移除相关的网络请求
- 在 collection view 数据源方法中处理这些 collection views

## 风险 / 权衡

### 风险 1: 影响现有用户体验
- **风险**: 用户习惯在详情页查看推荐和评论，移除后可能影响内容发现和社区互动
- **缓解**: 这是产品决策，接受此权衡以换取更专注的观看体验

### 风险 2: Storyboard 关联的 IBOutlet 断开
- **风险**: 如果 storyboard 中仍连接这些 outlets，运行时可能崩溃
- **缓解**: 
  - 将 outlets 标记为 optional (?)，避免崩溃
  - 或在 storyboard 中断开连接
  - 测试应用启动和详情页加载

### 风险 3: 相关的焦点导航问题
- **风险**: 移除 UI 元素后，tvOS 的焦点导航可能出现问题
- **缓解**: 测试焦点移动，确保用户仍能正常导航到所有可用功能

### 风险 4: 遗留的数据模型和网络请求
- **风险**: 可能遗漏某些相关代码，造成不必要的网络开销
- **缓解**: 
  - 仔细检查 `fetchData()` 方法
  - 移除 `replys` 属性和 `WebRequest.requestReplys` 调用
  - 移除推荐视频相关的数据绑定逻辑

## 实现方法

### 代码移除清单

1. **IBOutlet 和属性**
   - `@IBOutlet var recommandCollectionView: UICollectionView!` → 移除
   - `@IBOutlet var replysCollectionView: UICollectionView!` → 移除
   - `@IBOutlet var repliesCollectionViewHeightConstraints: NSLayoutConstraint!` → 移除
   - `private var replys: Replys?` → 移除

2. **网络请求**
   - `WebRequest.requestReplys(aid:)` 调用 → 移除
   - 移除请求推荐相关的数据绑定（如果有）

3. **UICollectionView DataSource/Delegate**
   - 在 `collectionView(_:numberOfItemsInSection:)` 中移除对这两个 collection views 的处理
   - 在 `collectionView(_:cellForItemAt:)` 中移除对这两个 collection views 的处理
   - 在 `collectionView(_:didSelectItemAt:)` 中移除对这两个 collection views 的处理

4. **UI 更新逻辑**
   - 在 `update(with:)` 中移除 `recommandCollectionView.reloadData()`
   - 移除 `recommandCollectionView.superview?.isHidden` 的设置逻辑
   - 移除与评论相关的 UI 更新

5. **Combine 订阅**
   - 移除 `replysCollectionView.publisher(for: \.contentSize)` 的订阅

6. **Focus Guide（如有）**
   - 检查并移除任何指向这些 collection views 的焦点引导

### 验证步骤

1. 编译检查：确保没有编译错误
2. 运行时检查：启动应用，打开视频详情页
3. 功能验证：
   - 核心信息正常显示（标题、UP主、统计数据）
   - 播放按钮可点击并正常播放
   - 点赞、投币、收藏功能正常
   - 分P列表正常展示和切换（如果有）
   - 合集列表正常展示和切换（如果有）
4. 焦点导航：测试 tvOS 遥控器导航是否流畅
5. 内存检查：确认不再发起推荐和评论的网络请求
