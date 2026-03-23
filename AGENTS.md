# AGENTS.md

## Agent 语言

- 思考和对外输出统一使用简体中文。

## Skill 可见性

- 在每一轮对话的第一条可见助手消息中，先输出一行以 `Skills:` 开头的内容。
- 用简洁的逗号分隔格式列出当前这一轮实际使用的所有 skill。
- 如果这一轮没有使用任何任务相关 skill，则输出 `Skills: none`。
- 保持这一行简短、便于快速扫读。
- 如果有帮助，可以在 skill 后面补一个很短的用途说明，例如 `Skills: brainstorming (设计), writing-plans (计划)`。
- 这条可见性规则优先于提问、分析、实现说明和结果总结，也就是说这些内容之前就要先显示 `Skills:` 这一行。

## 项目背景

- 技术栈为 Swift、SwiftUI。
- 仓库包含两个项目：
  - `BilibiliLive/` 是 tvOS 项目。
  - `BilibiliLive-iOS/` 是 iOS 项目。
- 当前开发重点是 iOS 项目，主要工作是将 tvOS 已有功能迁移到 iOS。

## iOS 开发原则

- tvOS 项目只作为功能和业务逻辑参考，不直接复用实现代码。
- 两个项目不要共享代码；iOS 需要的代码全部在 `BilibiliLive-iOS/` 内重新实现一份。
- 不要为了复用而抽离共享模块、共享 target、共享 package 或公共源码目录。
- 新需求、迁移需求和缺陷修复默认优先落在 iOS 项目，除非任务明确要求修改 tvOS 项目。
- 从 tvOS 迁移功能时，保留核心业务能力即可，界面结构、交互方式和导航设计应以 iOS 使用习惯为准，不照搬 tvOS 体验。

## 状态管理

- 在 iOS 项目中合理使用 Observation 框架，优先采用 `@Observable` 组织会驱动 SwiftUI 刷新的状态。
- 仅在状态需要被多个 SwiftUI 视图观察、共享或长期持有时使用 `@Observable`。
- 视图内部的局部瞬时状态优先使用 `@State`，视图之间的简单传值优先使用 `@Binding`。
- 需要在视图中对 `@Observable` 模型进行双向绑定时，优先使用 `@Bindable`。
- 不要为了统一写法而把所有模型都声明为 `@Observable`；保持状态边界清晰、职责单一。

## Xcode 与 MCP

- 所有 Xcode 相关操作优先通过 xcode-tools MCP 完成，包括编译、运行、调试、查看工程配置、scheme 和 destination。
- 非必要不要手动修改 Xcode 工程配置；如果必须调整工程设置，先确认是否有对应的 MCP 操作可以完成。
- 在反馈构建、运行或调试结果时，应明确说明执行了哪些 MCP 操作，以及关键结论或失败信息。
- 使用 xcodebuild 命令之前先试试 xcode-tools mcp是否可用。
