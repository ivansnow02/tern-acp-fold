# Tern ACP 工具分组

[English](README.md)

将 Tern 内置 ACP 聊天里连续的工具调用和 thoughts 合并为一条可点击摘要：

```text
Worked for 47.0s · Locating missing client-side remote styles · 3 thoughts ›
```

点击摘要展开原始内容，再次点击同一个原生折叠标题收起。内容顺序和各成员自己的展开状态保持不变。

## 安装

在运行 **Tern 桌面窗口的客户端** 上执行：

```sh
tern plugin install github.com/ivansnow02/tern-acp-fold
```

默认开启，覆盖窗口内已有的本机和远端 ACP 窗格，包括 Codex、Claude Code。无需重启远端 agent。使用多个桌面客户端时，每个客户端都需要安装。

仅安装到远端服务器，不会把窗口插件安装到本机。浏览器客户端不运行窗口端 Luau 插件。

## 使用

在命令面板中搜索 **ACP: Toggle tool groups** 或 **切换工具分组**，即可关闭或开启分组。

- 工具调用和思考块完成后，由后续消息结束这一段，再合并显示；单个已完成工具也会显示紧凑摘要。
- 后续用户消息会结束上一回合，使被打断回合末尾已完成的工具也能折叠。被截断的快照和当前仍在增长的末尾保持展开。
- 摘要优先采用第一个可用的工具 `intent`；没有时显示工具名和次数。调用前的说明保留在正文中。
- thoughts 数量来自 ACP agent 提供的思考块，不额外调用模型生成摘要。
- 已结束的失败和取消调用可以归组。摘要右侧独立显示失败、取消次数；失败使用错误色，动作描述过长也不会挤掉状态提示。
- 已完成的内联 Glob、Grep、Read 等工具，以及没有独立折叠按钮的失败调用，会与卡片和思考块归入同一段。
- 运行中和待审批的调用保持可见；整段都没有原生折叠按钮时，保留原样。
- 分组使用段内第一个可折叠成员控制展开，即使前面还有内联工具；该成员已经展开时，这组也保持展开。
- 耗时是各工具和思考块所报告时长的总和；并行调用存在重叠时，可能大于实际经过时间。

## 更新与卸载

更新已安装的副本：

```sh
tern plugin install github.com/ivansnow02/tern-acp-fold --force
```

卸载：

```sh
tern plugin remove acp-fold
```

开发时可用 `tern plugin link /本机路径/tern-acp-fold` 链接源码，修改后执行 `tern plugin reload acp-fold`。解除源码链接使用 `tern plugin unlink acp-fold`。

## 兼容性

已验证 macOS、**Tern 0.9.14**、本机 Claude Code ACP 和远端 Codex ACP。Linux、Windows 尚未验证。

插件通过 `cx.session:surface` 读取内置 ACP 的节点，在客户端安装 CSS，不修改 ACP 消息或模型配置。它依赖当前的 `acp` surface、`omp.assistant` / `omp.thinking` 角色，以及 tool、section 的内部 head/body 类名。后续 Tern 版本修改这些结构时，需要相应适配。

工作期间每秒检查 ACP 窗格；样式内容变化时才替换样式表。回合范围内的 `:active` 规则处理 Tern 0.9.14 在点击折叠按钮后，较远的相邻节点样式未及时刷新的问题。

## 许可证

[MIT](LICENSE)。
