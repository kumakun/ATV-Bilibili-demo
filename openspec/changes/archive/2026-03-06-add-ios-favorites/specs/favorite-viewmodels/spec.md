## 新增需求

### 需求：定义 FavoriteViewModel
系统必须定义 FavoriteViewModel 类管理收藏夹列表的状态和业务逻辑。

#### 场景：ViewModel 使用 @Observable
- **当** 定义 FavoriteViewModel
- **那么** 必须使用 @Observable 宏标记，确保 SwiftUI 自动响应状态变化

#### 场景：ViewModel 在主线程运行
- **当** FavoriteViewModel 方法被调用
- **那么** 必须使用 @MainActor 确保所有 UI 相关操作在主线程执行

### 需求：FavoriteViewModel 管理收藏夹列表状态
系统必须在 FavoriteViewModel 中管理收藏夹列表的状态数据。

#### 场景：存储收藏夹列表
- **当** 加载收藏夹数据成功
- **那么** ViewModel 必须将数据存储在 folders 属性中（类型为 [FavListData]）

#### 场景：管理加载状态
- **当** 加载收藏夹数据时
- **那么** ViewModel 必须维护 isLoading（布尔值）状态

#### 场景：管理错误状态
- **当** 加载失败时
- **那么** ViewModel 必须将错误信息存储在 errorMessage（可选字符串）属性中

### 需求：FavoriteViewModel 提供加载方法
系统必须在 FavoriteViewModel 中提供加载收藏夹列表的方法。

#### 场景：初始加载
- **当** 视图首次出现时调用 loadFolders() 方法
- **那么** 系统必须设置 isLoading 为 true，调用 API，成功后更新 folders，失败则设置 errorMessage

#### 场景：刷新加载
- **当** 用户触发刷新时调用 refresh() 方法
- **那么** 系统必须清空当前数据并重新加载

### 需求：FavoriteViewModel 合并自建和订阅收藏夹
系统必须在 FavoriteViewModel 中合并用户自建收藏夹和订阅收藏夹。

#### 场景：加载两种类型收藏夹
- **当** loadFolders() 方法执行
- **那么** 系统必须依次调用 requestFavVideosList() 和 requestFavFolderCollectedList()，并将结果合并到 folders 数组

#### 场景：标记收藏夹类型
- **当** 加载自建收藏夹
- **那么** 系统必须将 isCreatedBySelf 设置为 true

### 需求：定义 FavoriteFolderViewModel
系统必须定义 FavoriteFolderViewModel 类管理单个收藏夹内容的状态和分页逻辑。

#### 场景：ViewModel 使用 @Observable
- **当** 定义 FavoriteFolderViewModel
- **那么** 必须使用 @Observable 宏标记

#### 场景：ViewModel 初始化
- **当** 创建 FavoriteFolderViewModel 实例
- **那么** 必须接受 folder（FavListData）参数

### 需求：FavoriteFolderViewModel 管理视频列表状态
系统必须在 FavoriteFolderViewModel 中管理视频列表和分页状态。

#### 场景：存储视频列表
- **当** 加载视频数据成功
- **那么** ViewModel 必须将数据存储在 videos 属性中（类型为 [FavData]）

#### 场景：管理分页状态
- **当** 进行分页加载时
- **那么** ViewModel 必须维护 currentPage（当前页码）、hasMore（是否还有更多数据）和 isLoadingMore（是否正在加载更多）状态

#### 场景：管理首次加载状态
- **当** 首次加载数据时
- **那么** ViewModel 必须维护 isLoading 和 errorMessage 状态

### 需求：FavoriteFolderViewModel 提供加载方法
系统必须在 FavoriteFolderViewModel 中提供加载视频列表的方法。

#### 场景：初始加载
- **当** 视图首次出现时调用 loadVideos() 方法
- **那么** 系统必须设置 isLoading 为 true，加载第一页数据，成功后更新 videos 和 currentPage

#### 场景：加载更多
- **当** 用户滚动到底部时调用 loadMore() 方法
- **那么** 系统必须检查 hasMore，设置 isLoadingMore，加载下一页数据并追加到 videos 数组

#### 场景：刷新
- **当** 用户下拉刷新时调用 refresh() 方法
- **那么** 系统必须重置 currentPage 为 1，清空 videos，重新加载首页数据

### 需求：FavoriteFolderViewModel 处理不同类型收藏夹
系统必须根据收藏夹类型调用不同的 API。

#### 场景：加载自建收藏夹内容
- **当** folder.isCreatedBySelf 为 true
- **那么** 系统必须调用 requestFavVideos(mediaId:page:) API

#### 场景：加载订阅收藏夹内容
- **当** folder.isCreatedBySelf 为 false
- **那么** 系统必须调用 requestFavSeason(seasonId:page:) API（使用 folder.id 作为 seasonId）

### 需求：ViewModel 提供视频跳转方法
系统必须在 FavoriteFolderViewModel 中提供视频跳转的接口方法。

#### 场景：跳转普通视频
- **当** 用户点击普通视频
- **那么** ViewModel 必须提供 navigateToVideo(_:) 方法，接受 FavData 参数

#### 场景：跳转 OGV 内容
- **当** 用户点击番剧或影视内容
- **那么** 系统必须检查 video.ogv 是否存在，存在则使用 season_id 跳转

### 需求：ViewModel 错误处理
系统必须在 ViewModel 中妥善处理各种错误情况。

#### 场景：网络错误
- **当** API 请求因网络原因失败
- **那么** ViewModel 必须捕获错误，设置 errorMessage 为友好的提示信息（如"网络连接失败，请检查网络设置"）

#### 场景：API 错误
- **当** API 返回错误响应
- **那么** ViewModel 必须解析错误信息并展示给用户

#### 场景：未登录错误
- **当** 用户未登录时尝试加载收藏
- **那么** ViewModel 必须提前检查登录状态，设置相应的错误提示
