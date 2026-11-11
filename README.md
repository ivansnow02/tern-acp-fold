# ACP Tool Groups for Tern

[简体中文](README.zh-CN.md)

A [Tern](https://stencil.so/tern) desktop plugin that groups consecutive ACP tool
calls and thoughts into a clickable summary:

```text
Worked for 47.0s · Locating missing client-side remote styles · 3 thoughts ›
```

Click the summary to reveal the original items in order. Click the same native
disclosure header again to collapse the group. Each item's own expanded state is preserved.

## Install

Run this on the computer running your **Tern desktop window**:

```sh
tern plugin install github.com/ivansnow02/tern-acp-fold
```

The plugin is enabled by default. It covers existing local and remote ACP panes
in that window, including Codex and Claude Code. A remote agent does not need to
restart. With several desktop clients, install the plugin on each client.

Installing only on the remote server does not install this window plugin on your
desktop. The browser client does not run window-side Luau plugins.

## Use

Open Tern's command palette and search for **ACP: Toggle tool groups** or
**切换工具分组** to turn grouping off or on.

- Completed tool calls and thoughts form a group after a later message closes
  the sequence. A completed single tool also gets a compact summary.
- A later user message closes the preceding turn's completed tail, including
  interrupted turns. Truncated snapshots and the current growing tail stay open.
- The summary uses the first available tool intent, then the first line of the
  agent's preceding explanation. If neither exists, it lists tool names and counts.
- Thought counts use the thinking blocks supplied by the ACP agent. Summaries
  require no additional model calls.
- Settled failures and cancellations can fold with completed work. A separate
  status label preserves their counts; failures use the error color, and long
  descriptions cannot truncate that label.
- Completed inline tools, including Glob, Grep, Read and failed calls without their
  own disclosure, join the same sequence as tool cards and thoughts.
- Running and approval-pending items stay visible. A sequence with no native
  disclosure keeps its normal view.
- The first available native disclosure controls the group, even after inline
  items. If that disclosure is already expanded, the group remains expanded.
- Displayed time sums the durations reported for the group's tools and thoughts;
  overlapping calls can make it longer than wall-clock time.

## Update or remove

Update an installed copy:

```sh
tern plugin install github.com/ivansnow02/tern-acp-fold --force
```

Remove it:

```sh
tern plugin remove acp-fold
```

For a local development checkout, use `tern plugin link /path/to/tern-acp-fold`.
Reload it with `tern plugin reload acp-fold`, or unlink it with
`tern plugin unlink acp-fold`.

## Compatibility

Tested on macOS with **Tern 0.9.14**, local Claude Code ACP, and remote Codex ACP.
Linux and Windows have not been verified.

This targets Tern's built-in ACP chat surface. It reads `cx.session:surface` and
installs client-side CSS; it does not change ACP messages or model configuration.
It depends on the current `acp` surface, `omp.assistant` / `omp.thinking` roles,
and the internal tool and section head/body classes. Changes to those structures
in later Tern versions may require an update.

The plugin refreshes busy ACP panes once per second and only replaces a sheet
when its content changes. A scoped `:active` rule handles Tern 0.9.14's stale
styles for distant adjacent siblings when a disclosure is clicked.

## License

[MIT](LICENSE).

