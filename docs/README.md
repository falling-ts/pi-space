# docs/ — 文档索引

本目录存放关于 `pi` 及其生态的正式文档。一个主题一个文件，命名用 `短横线小写.md`。

## 规划中的文档

| 文件 | 主题 | 状态 |
| --- | --- | --- |
| `pi-overview.md` | 上游 pi 的定位、包结构与入口 | 待写 |
| `pi-architecture.md` | 核心架构：agent loop、工具系统、会话模型 | 待写 |
| `pi-dev-setup.md` | 本地构建/运行/调试 pi 的步骤 | 待写 |
| `decisions.md` | 本空间的关键决策记录（含参考项目接入方式） | 待写 |

## 写作约定

- 结论先行：每篇开头 3–5 行给出结论与适用版本（写明上游 commit 短 SHA）。
- 引用上游源码时给相对路径，例如 `refs/pi/packages/...`，并附 commit。
- 与 `refs/` 的版本强相关的结论，必须在标题下注明 `upstream: <sha>`。

## 相关

- 空间规则：[`../AGENTS.md`](../AGENTS.md)
- 参考项目：[`../refs/README.md`](../refs/README.md)
