## 1. 梳理二级页面范围

- [x] 1.1 盘点 `BilibiliLive-iOS` 中主 Tab 内所有通过 `NavigationLink` 或 `navigationDestination` 进入的二级页面
- [x] 1.2 确认哪些页面属于 push 式二级页面，并排除不需要处理的 sheet 与 iPad split view 常驻布局

## 2. 实现 Tab Bar 隐藏规则

- [x] 2.1 为视频详情页添加主 Tab Bar 隐藏声明，确保从关注页和收藏页进入时底部主 Tab 不显示
- [x] 2.2 为收藏夹详情、历史记录、稍后再看、每周必看、关注 UP、追番追剧等二级页面补齐一致的主 Tab Bar 隐藏规则
- [x] 2.3 如有必要，抽取复用的二级页面修饰器或辅助封装，避免重复编写隐藏逻辑

## 3. 验证导航行为

- [x] 3.1 在 iPhone 模式下验证从关注、收藏、我的进入二级页面时主 Tab Bar 会隐藏
- [x] 3.2 验证从视频详情页和其他二级页面返回一级页面后主 Tab Bar 会恢复显示
- [x] 3.3 在 iPad 模式下验证现有 `NavigationSplitView` 顶层结构未被破坏，且更深层 push 页面行为符合预期
