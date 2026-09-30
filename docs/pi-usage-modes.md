# pi 的使用方式总览

upstream: 1b347794（`refs/pi`，`origin/main`，版本 `pi-monorepo@0.0.3` / 各包 `0.99.1`）

结论先行：pi 不是一个「只能敲 `pi` 的终端工具」，而是一套 agent harness。使用方式可以分成 **6 类**，从最常用到最底层依次是：

| # | 使用方式 | 一句话 | 入口 |
| --- | --- | --- | --- |
| 1 | 终端交互使用 | 人在终端里和 pi 对话干活 | `pi` |
| 2 | 目录内定制 | 用配置/提示/技能/扩展改造 pi 的行为 | `.pi/`、`~/.pi/agent/` |
| 3 | 进程自动化 | 把它当一次性命令或长驻子进程调用 | `-p`、`--mode json`、`--mode rpc` |
| 4 | 代码内嵌 SDK | 在自己的 Node/Bun 程序里直接跑 agent | `createAgentSession()` |
| 5 | 构建自己的产品 | fork/改名，或复用底层包自建 harness | `piConfig`、`packages/*` |
| 6 | 无人值守/隔离托管 | CI、容器、微 VM 里无人工干预地跑 | print 模式 + 沙箱 |

上游文档自己给出的选型表在 `packages/coding-agent/docs/cli-integration.md:11-16`（四种 CLI 模式对比），定制机制的选型表在 `packages/coding-agent/docs/quickstart.md:98-106`。

---

## 1. 终端交互使用

- 安装：`curl -fsSL https://pi.dev/install.sh | sh`（macOS/Linux 安装脚本，交互式可选择卸载）或 `npm install -g --ignore-scripts @earendil-works/pi-coding-agent`（需 Node ≥ 22.19）。见 `packages/coding-agent/docs/quickstart.md:9-27`。
- 启动：`cd <工作目录> && pi`；工作目录决定项目配置、资源发现与会话分组（`quickstart.md:31-38`）。
- 带初始 prompt：`pi "Read package.json" "What dependencies do we have?"`；`@path` 把文件/图片塞进首条消息，`@` 在编辑器里触发文件搜索（`cli.md:32-39`、`quickstart.md:76`）。
- 管道输入：`git diff | pi --print "Review this change"`（`cli.md:25-28`）。
- 会话：`pi -c` 续上一会话、`pi -r` 选会话、`--session/--session-id/--fork/--name`、`/resume`（`cli.md:78-107`、`quickstart.md:78-86`）。
- 会话结果外带：`/export` 导出 HTML/JSONL，`/share` 上传并拿到查看链接（配了 Radius 认证就存 Radius artifact，否则建私有 GitHub gist）；另有 `pi --export` 非交互导出（`docs/sessions.md:58`、`docs/usage.md:82`、`cli.md:49`）。
- 交互界面能力入口：slash commands（`/login`、`/model`、`/resume` 等）、prompt templates（`/` 菜单）、快捷键、主题、消息排队。见 `docs/slash-commands.md`、`docs/keybindings.md`、`docs/usage.md`。
- 子命令：`install` / `remove`(`uninstall`) / `update` / `list` / `config` / `auth` / `mcp`，完整用法见 `docs/cli.md:7-17` 与 `docs/cli.md:248-329`。
- 平台差异：原生 Windows、WSL、Android Termux、tmux 各有专页（`docs/windows.md`、`docs/termux.md`、`docs/tmux.md`、`docs/terminal-setup.md`）；Windows 上多一个 `powershell` 内置工具（`cli.md:134`）。
- 开发者包装脚本：`scripts/auto-pi.sh` 把 checkout 里的最新构建做成 `pi` 符号链接，默认带 `PI_EXPERIMENTAL=1`（`scripts/auto-pi.sh:1-13`）。

## 2. 目录内定制（不写代码就能改行为）

上游明确建议「从满足需求的最小机制开始」（`quickstart.md:94-106`）：

| 需求 | 机制 | 文档 |
| --- | --- | --- |
| 给某个目录持久指令 | `AGENTS.md`（context files，也认 `CLAUDE.md`） | `docs/configuration.md` |
| 复用一段提示 | prompt template | `docs/prompt-templates.md` |
| 加任务的专门指令与附带文件 | skill | `docs/skills.md` |
| 加可执行工具/命令/事件处理 | extension | `docs/extensions.md` |
| 自定义终端组件 | TUI 组件 | `docs/tui.md` |
| 接不支持的模型服务 | custom provider | `docs/custom-provider.md` |
| 打包分发以上资源 | pi package | `docs/packages.md` |

- 配置位置：`~/.pi/agent/`（全局）与 `<项目>/.pi/`（项目级）；全局/项目级用 `-l/--local` 区分（`cli.md:265`、`cli.md:327`）。
- 资源可以按次加载或禁用：`-e/--extension`、`--skill`、`--prompt-template`、`--theme` 以及对应的 `-ne/-ns/-np/--no-themes/-nc` 开关（`cli.md:186-215`）。
- 项目级资源受 project trust 门控，需要 `-a/--approve` 或交互确认（`cli.md:235-238`、`docs/security.md`）。
- 上游仓库自身就是例子：`.pi/prompts/*.md`、`.pi/skills/*.md`、`.pi/extensions/*.ts`。

## 3. 进程自动化（脚本 / 其他程序驱动）

四种模式共用同一个 agent、会话、资源与工具，差别只在输入怎么进、输出怎么出、进程活多久（`cli-integration.md:5`、`cli-integration.md:11-16`）：

| 模式 | 命令 | 生命周期 | 适用 |
| --- | --- | --- | --- |
| Print | `pi -p "…"` | 一次调用 | 只要最终文本（管道、命令替换、一次性任务） |
| JSON | `pi --mode json "…" > events.jsonl` | 一次调用 | 需要结构化过程事件 |
| RPC | `pi --mode rpc --no-session` | 长驻 | 需要双向控制（改模型、查状态、跑命令、应答扩展 UI） |

- 默认模式不是"永远 TUI"：stdin 或 stdout 非 TTY 时自动切 print 模式（`cli-integration.md:32`）。
- Print 模式把错误写 stderr；`error`/`aborted` 结束原因会给出非零退出码（`cli-integration.md:30`）。
- JSON 模式 stdout 专供 JSONL，`agent_settled` 才表示这一轮自动工作结束（`cli-integration.md:36-52`）。
- RPC 模式的 `prompt` 响应只表示"已受理"，不等于跑完（`cli-integration.md:56-70`）。
- RPC 只有 stdin/stdout 一条通道：没有内建 HTTP/WebSocket 服务端，远端会话要靠实验性的 `pi server` + `pi client`（CBOR over unix/radius，见第 5 节）。
- Node 侧优先用 `RpcClient`（`@earendil-works/pi-coding-agent` 导出，实现见 `src/modes/rpc/rpc-client.ts`），示例在 `examples/rpc-client.ts`、`examples/rpc-extension-ui.ts`（`cli-integration.md:72-80`）。
- 实测（上游 CI 用法）：`node packages/coding-agent/src/cli.ts -p --approve --session-dir <dir> --model openai-codex/gpt-5.5 --thinking high "/is <issue-url>"`，见 `.github/workflows/issue-analysis.yml:383-394`。
- 会话可导出成 HTML 再分享：`pi --no-extensions --export <session.jsonl> <out.html>`（`cli.md:49`、`.github/workflows/issue-analysis.yml:529`）。
- `pi auth print-api-key` / `print-bearer-token` 可以把凭据交给外部客户端，`pi mcp list/add/login/logout` 可以在会话外由 agent 通过 `bash` 调用（`cli.md:289-327`）。

## 4. 代码内嵌 SDK

- 入口：`createAgentSession()` / `createAgentSessionRuntime()`，来自 `@earendil-works/pi-coding-agent`；模型来自 `@earendil-works/pi-ai` 的 `getModel()`。最小骨架与选项表见 `packages/coding-agent/examples/sdk/README.md:35-118`。
- 可控制：模型与 thinking 等级、system prompt 覆写、工具 allowlist、`customTools`、skills/prompts/context files 的发现或替换、session 持久化（内存/落盘/续接）、settings、扩展工厂（`examples/sdk/README.md:47-103`）。
- 事件订阅：`session.subscribe()`，含 `message_update`（`text_delta`）、`tool_execution_start/end`、`agent_settled`（`examples/sdk/README.md:120-140`）。
- 14 个渐进示例：`examples/sdk/01-minimal.ts` … `14-codemode-mcp.ts`，覆盖自定义模型、只读工具集、内存会话、全手工控制、MCP+codemode（`examples/sdk/README.md:9-24`）。
- 官方定位：SDK **不是** 一种 CLI 模式，而是把 agent 直接嵌进 Node/Bun 进程（`cli-integration.md:7`）。
- 源码层面佐证：`src/modes/` 下就是 `interactive/`、`print-mode.ts`、`json-event.ts`、`rpc/` 四套实现；SDK 入口在 `src/core/sdk.ts`（`createAgentSession`、`createAgentSessionRuntime`），`src/index.ts` 另外导出 `DefaultResourceLoader`、`ModelRuntime`、`SessionManager` 以及 `createMcpExtension`、`createCodemodeExtension`、`createToolSearchExtension` 等扩展工厂。

## 5. 构建自己的产品

- Fork/改名：`package.json` 的 `piConfig.name` / `piConfig.configDir` 改 CLI 名称与配置目录，`bin` 改可执行名，会影响横幅、配置路径与派生环境变量（`cli-integration.md:82-95`）。
- 独立二进制：上游用 `bun build --compile` 出 `dist/pi`（`packages/coding-agent/package.json` 的 `build:binary`），release 源码包可自行构建（根 `README.md:65-76`）。
- 复用底层包自建 harness（根 `README.md:26-38`）：`pi-ai`（多供应商 LLM API）、`pi-agent-core`（工具调用与状态）、`pi-tui`（差分渲染终端 UI）、`pi-durable`（持久会话/任务/文档）、`chord`（服务组合、RPC、插件）、`pi-telemetry`、`pi-protocol` + `pi-client` + `pi-server`（远端会话的 CBOR 协议，见各包 `package.json` 的 description）。
- 实验性的 `pi server` / `pi client` 子命令（远端会话服务与客户端）需要 `PI_EXPERIMENTAL=1`（`src/cli/experimental/cli.ts:1-16`、`src/core/experimental.ts:1-3`）。
- 上层产品形态由上游生态承接：Slack/聊天自动化用 `earendil-works/pi-chat`，会话发布用 `badlogic/pi-share-hf`（根 `README.md:38`、`README.md:100`）。

## 6. 无人值守与隔离托管

- 权限模型：pi **没有**内置权限系统，工具以启动进程的权限运行；project trust 只决定加载哪些项目资源，不构成沙箱（根 `README.md:41-48`、`docs/security.md`）。
- 三种隔离模式（根 `README.md:44-48`、`docs/containerization.md:155`）：Gondolin 扩展（宿主保留 pi 与凭据，工具进本地 Linux micro-VM）、纯 Docker（整个 pi 进程进容器）、OpenShell（策略沙箱）。
- CI 用法实例：GitHub Actions 里 `-p --approve` 无人值守跑 `/is`，把 auth.json 放 `PI_CODING_AGENT_DIR`，跑完导出会话 HTML 传 gist 并回帖（`.github/workflows/issue-analysis.yml`）。
- 环境控制：`--offline` / `PI_OFFLINE=1` 关掉启动网络操作，`PI_CODING_AGENT_DIR`、`PI_CODING_AGENT_SESSION_DIR` 改配置与会话目录（`cli.md:239-240`、`cli.md:97`、`docs/environment-variables.md`）。

---

## 尚未核实

- `pi.dev/docs/latest` 在线文档与本地 `docs/` 的差异（本地为上游 1b347794 时点快照）。
- `pi-chat`、`pi-share-hf`、`pi-server`/`pi-client` 的实际成熟度（后者标注 experimental，且未在上游发布包 `files` 清单中）。
- 上游发布的独立二进制在 Windows 上的安装路径与包管理器渠道（`docs/windows.md` 未在本篇逐行核对）。
