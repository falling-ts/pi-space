# pi 使用方式总览

upstream: 1b347794（`refs/pi`，跟踪 `origin/main`；`pi-monorepo@0.0.3`，各包 `0.99.1`，`engines.node >= 22.19.0`）

**路径约定**（本文所有证据路径都相对仓库根 `refs/pi/`，为省字数使用简写）：

| 简写 | 实际路径 |
| --- | --- |
| `docs/` | `packages/coding-agent/docs/` |
| `src/` | `packages/coding-agent/src/` |
| `examples/` | `packages/coding-agent/examples/` |
| `pkgs/<name>/` | `packages/<name>/` |

## 结论先行：6 类使用方式

| # | 使用方式 | 一句话 | 入口 |
| --- | --- | --- | --- |
| 1 | 终端交互 | 人在终端里对话干活 | `pi` |
| 2 | 目录内定制 | 配置/提示/技能/扩展改造行为 | `.pi/`、`~/.pi/agent/` |
| 3 | 进程自动化 | 当一次性命令或长驻子进程调用 | `-p`、`--mode json`、`--mode rpc` |
| 4 | 代码内嵌 SDK | 在自己的 Node/Bun 程序里跑 agent | `createAgentSession()` |
| 5 | 自建产品 | 复用底层包造 harness，或 fork 改名 | `pkgs/*`、`piConfig` |
| 6 | 无人值守托管 | CI/容器/微 VM 里无人干预地跑 | print 模式 + 沙箱 |

选型依据来自上游自己：四种 CLI 模式对照在 `docs/cli-integration.md:11-16`，定制机制「从最小够用的开始」在 `docs/quickstart.md:98-106`，上游文档全貌见本文附录 A。

---

## 1. 终端交互使用

### 1.1 安装方式

| 方式 | 命令 / 产物 | 证据 |
| --- | --- | --- |
| 官方安装脚本（仅 macOS/Linux） | `curl -fsSL https://pi.dev/install.sh \| sh`；重跑可选 Uninstall Pi | `docs/quickstart.md:9-13,108-122` |
| npm 全局（Node ≥ 22.19） | `npm install -g --ignore-scripts @earendil-works/pi-coding-agent` | `docs/quickstart.md:15-19` |
| 独立二进制 | release 资产 `pi-{darwin,linux}-{arm64,x64}.tar.gz`、`pi-windows-{x64,arm64}.zip` + `SHA256SUMS` | `.github/workflows/build-binaries.yml:94-121` |
| 从 release 源码自编译 | `./scripts/build-binaries.sh --offline-model-data --platform linux-x64 --out out` | 根 `README.md:65-76` |
| 源码运行（开发） | `npm install --ignore-scripts` 后 `./pi-test.sh`（Windows 用 `pi-test.ps1` / `pi-test.bat`） | `pkgs/coding-agent/README.md:48-57` |
| 容器内 | Dockerfile 里 npm 全局安装，`docker build -t pi-sandbox -f Dockerfile.pi .` | `docs/containerization.md:36-68` |
| Termux（Android） | `pkg install nodejs git` 后 npm 全局安装；需 F-Droid/GitHub 版 Termux | `docs/termux.md:5-44` |
| 自更新 | `pi update`（取决于安装方式；Windows 仅 npm/pnpm） | `docs/cli.md:267-279`、`src/package-manager-cli.ts:1058-1066` |

`npx` 与 pnpm/yarn/bun 全局安装命令文档均未给出（代码里只有安装方式识别与自更新命令生成，`src/config.ts:79-171`）。

### 1.2 启动与调用形式

- 判定规则：stdin 与 stdout 都是终端就开 TUI，除非指定 `--print` / `--mode json` / `--mode rpc`；任一流被重定向且未选 JSON/RPC 时用 print（`docs/cli.md:30`，实现 `src/main.ts:112-123`）。
- 首条 prompt 的四种来源：位置参数 `message`、`@path`（文本或图片，相对 cwd 解析）、管道 stdin 前置拼接、`--` 终止选项解析（`docs/cli.md:32-39`）。
- 完整 flag 面见 `docs/cli.md:43-244` 与 `src/cli/args.ts:272-397`；约束：`--fork` 不能与 `--session/--continue/--resume/--no-session` 同用，`--session-id` 不能与 `--session/--continue/--resume` 同用，RPC 模式拒绝 `@file`（`docs/cli.md:103-107`、`src/main.ts:299-336,651-654`）。
- 子命令：`install` / `remove`(`uninstall`) / `update` / `list` / `config` / `auth` / `mcp`（`docs/cli.md:7-17`）；包源支持 `npm:`、`git:`、URL、`ssh://`、本地路径（`docs/packages.md:9-40`）。
- 扩展可以注册额外的长选项，所以实际帮助以 `pi --help` 为准（`docs/cli.md:246`）。

### 1.3 TUI 内的能力入口

| 入口 | 内容 | 证据 |
| --- | --- | --- |
| 斜杠命令 | `/model` `/thinking` `/settings` `/login` `/new` `/resume` `/name` `/tree` `/fork` `/clone` `/compact` `/export` `/share` `/bug` `/trust` `/reload` `/hotkeys` `/quit` | `docs/slash-commands.md:3-52` |
| 资源附加命令 | prompt template 名即命令、skill 为 `/skill:name`、扩展可注册命令；改完资源 `/reload` | `docs/slash-commands.md:54-60` |
| shell 转义 | `!cmd` 输出进上下文，`!!cmd` 不进 | `docs/usage.md:70-76` |
| 运行中引导 | `Enter` 修正、`Alt+Enter` 追加（Win/WSL 为 `Ctrl+Q`）、`Alt+Up` 取回队列、`Escape` 中止 | `docs/usage.md:31-40` |
| 键位自定义 | `<agent-dir>/keybindings.json`，action 形如 `app.session.new`（空数组=禁用） | `docs/keybindings.md:7-28` |
| 终端模式 | regular（用终端自身 scrollback）/ fullscreen，走 `/settings` 或 `--tui-mode` | `docs/usage.md:86-88` |
| 诊断 | `/hotkeys`；`/debug` 把渲染行与消息写入 agent 目录的 `pi-debug.log` | `docs/usage.md:88-94` |
| 结果外带 | `/export`（HTML/JSONL）、`/share`（上传换查看链接；配 Radius 存 artifact，否则建私有 gist）、`pi --export <in> [out]` | `docs/sessions.md:58`、`docs/usage.md:82`、`docs/cli.md:49` |

### 1.4 会话、分支与压缩

- 会话自动保存（`--no-session` 关闭）；`/new`、`/resume`（搜索/重命名/删除）、`/name`、`/session`（文件、ID、消息数、token、成本）（`docs/sessions.md:5-34,48-58`）。
- 分支：`/tree` 在同文件内移动、`/fork` 从早期用户消息新建会话、`/clone` 复制当前分支；离开分支时可选把旧分支摘要注入新分支（`docs/sessions.md:5-34`）。
- 压缩：自动触发条件 `contextTokens > contextWindow - reserveTokens`（默认 reserve 16384、keepRecent 20000）；`compaction.enabled=false` 只关自动，`/compact [instructions]` 仍可用；压缩不删除原始条目，可用 `compaction.modelOverrides` 按 `provider/modelId` 调参（`docs/compaction.md:29-49,417-461`）。

### 1.5 平台差异

| 平台 | 关键点 | 证据 |
| --- | --- | --- |
| Windows 原生 | `bash` 工具默认用 Git Bash（`shellPath` 可改），可换成 `powershell` 工具（`"defaultTools": ["read","powershell","edit","write"]`）；`Alt+Enter` 被 Windows Terminal 占用，pi 改用 `Ctrl+Q` 追加、`Alt+Q` 取回 | `docs/windows.md:9-61`、`docs/terminal-setup.md:167-188` |
| WSL | 用发行版内 Linux 工具链；CJK 输入法候选框漂移可 `export PI_HARDWARE_CURSOR=1` | `docs/windows.md:9-13`、`docs/terminal-setup.md:107-116` |
| tmux | 需 `set -g extended-keys on`（≥3.5 再加 `extended-keys-format csi-u`），否则 Shift+Enter 与 Enter 无法区分 | `docs/tmux.md:5-55` |
| Termux | 需 `termux-setup-storage` 访问共享存储；剪贴板要装 `termux-api`，且不支持粘贴图片 | `docs/termux.md:46-75` |

---

## 2. 目录内定制（不写代码就能改行为）

### 2.1 机制对照

| 需求 | 机制 | 放哪 | 证据 |
| --- | --- | --- | --- |
| 给目录持久指令 | `AGENTS.md` / `AGENTS.override.md` / `CLAUDE.md`（context files，**不需要 trust**） | agent 目录、cwd 及各级父目录 | `docs/configuration.md:43-47` |
| 复用一段提示 | prompt template（一个 `.md` = 一个 `/命令`，支持 `$1`/`$@`/`${1:-默认}`） | `<agent-dir>/prompts/`、`.pi/prompts/` | `docs/prompt-templates.md:9-23,40-57` |
| 加任务的专门指令 | skill（含 `SKILL.md` 的目录；启动只注入 name/description，命中才读全文） | `<agent-dir>/skills/`、`.pi/skills/`、`~/.agents/skills/`、`.agents/skills/` | `docs/skills.md:11-22,43-45,59-63` |
| 加可执行工具/命令/hook | extension（默认导出工厂 `export default (pi: ExtensionAPI) => {…}`，jiti 直跑无需编译） | `<agent-dir>/extensions/`、`.pi/extensions/`，或 `pi -e ./x.ts` | `docs/extensions.md:15,35-48` |
| 换配色 | theme（JSON 调色板） | `<agent-dir>/themes/<name>.json`、`.pi/themes/` | `docs/themes.md:40-48,61-79` |
| 打包分发以上资源 | pi package | `pi install <source>` | `docs/packages.md:9-27` |
| 改整体系统提示 | `SYSTEM.md`（替换）/ `APPEND_SYSTEM.md`（追加），trusted 项目文件优先于 agent 目录 | agent 目录、`.pi/` | `docs/configuration.md:13-39` |

### 2.2 扩展：生命周期与能改什么

- 发现规则：直接 `.ts`/`.js` 文件，或含 `index.ts`/`index.js` 的子目录；npm 依赖放同目录 `package.json`（`docs/extensions.md:46-48`）。
- 内置扩展可关：`builtin:mcp`、`builtin:llama.cpp`、`builtin:codemode`、`builtin:tool-search`，用 `"extensions": ["-builtin:mcp"]` 或 `--no-extensions`（`docs/settings.md:158`、`docs/cli.md:196-197`）。
- 约 35 个命名事件（`pi.on()`），覆盖资源发现、session、agent、message、tool、provider、原始输入与 UI；完整清单见 `src/core/extensions/types.ts:1540-1610`。
- 一轮的顺序：input → `before_agent_start` → 模型/message/tool 事件 → `agent_end`；之后仍可能有自动重试、压缩、排队（`docs/extensions.md:62`）。两个收尾边界：`agent_before_settle` 是最后可动作处，`agent_settled` 只通知（`docs/extensions.md:66-67`）。
- 可变换的事件：`before_agent_start`（改 prompt 分段/工具/guidelines 或整体替换）、`message_end`、`tool_call`（改输入或 `{block:true, reason}` 阻断）、`tool_result`、`context`/`context_with_system`、`turn_end`、`input`、`user_bash`（`docs/extensions.md:103-127`）。
- 能注册：工具、`/` 命令、快捷键、CLI flag、provider、MCP server、虚拟模型、消息渲染、UI 组件、扩展间事件总线（`docs/extensions.md:73-86`）。
- 资源释放必须放在 `session_shutdown` 且幂等；`ctx.reload()` 会替换整个扩展运行时（`docs/extensions.md:50,258-260`）。
- 现成例子：`examples/extensions/` 有 70 个单文件 + 9 个目录，索引在各例 README 表格（`examples/extensions/README.md:19-139`），例如 `permission-gate.ts`（`tool_call` 危险命令确认）、`sandbox/`（OS 级限制 bash）、`subagent/`、`ssh.ts`（工具委派远端）、`custom-provider-*`、`plan-mode/`、`doom-overlay/`。

### 2.3 配置位置与优先级

- agent 目录默认 `~/.pi/agent`，用 `PI_CODING_AGENT_DIR` 或 SDK `agentDir` 改；内含 `settings.json`、`keybindings.json`、`mcp.json`、`models.json`、`auth.json`、`AGENTS.md`、`SYSTEM.md`、`extensions/`、`skills/`、`prompts/`、`themes/`（`docs/configuration.md:3-24`）。
- 项目侧 `.pi/` 有同名子集（`docs/configuration.md:30-37`）。
- 优先级：project settings 覆盖 user settings，但**资源列表是合并**（`docs/settings.md:3`）；`sessionDir` 是唯一在 trust 之前就被读取的例外（`docs/configuration.md:3`、`docs/security.md:31`）。
- 凭据解析顺序：`--api-key` > `auth.json` > `models.json` 的 `apiKey` > 供应商环境变量（`docs/models.md:23`）；`apiKey` 支持 `$NAME`、`${NAME}`、字面值与 `!command` 取密钥（`docs/models.md:64`）。

### 2.4 权限模型（重要）

- **没有内置权限/审批系统，也没有内置沙箱**：工具以 pi 进程的 OS 权限运行（`docs/security.md:3,99`、`docs/how-pi-works.md:47-49`）。
- 唯一内置的「门」是项目 trust，它只决定启动时加载哪些项目资源（`.pi/settings.json`、`.pi/mcp.json`、`.pi/{extensions,skills,prompts,themes}`、`.pi/SYSTEM.md` 等），**不限制工具能碰什么**（`docs/security.md:29-45`）。
- trust 决策顺序：`--approve`/`--no-approve` → 扩展的 `project_trust` 事件（第一个返回者定）→ `~/.pi/agent/trust.json` 里保存的目录决策 → `defaultProjectTrust`（默认 `ask`）（`docs/security.md:61-73`）。
- 非交互模式没有 trust 提示：`always` 加载受保护资源，`ask`/`never` 跳过，所以自动化里要么给 `--approve`，要么给 `--no-approve`（`docs/security.md:77-82`）。
- 真正的权限控制得靠扩展：`tool_call` 里阻断，或参考 `examples/extensions/permission-gate.ts:13-33` 与 `annotations`（readOnlyHint/destructiveHint 等）只拦破坏性调用（`docs/extensions.md:166-178`）。

---

## 3. 进程自动化（脚本 / 其他程序驱动）

### 3.1 四种模式对照

| 模式 | 命令 | 生命周期 | 适用 | 证据 |
| --- | --- | --- | --- | --- |
| Interactive | `pi` | 到用户退出 | 人在用 | `docs/cli-integration.md:13` |
| Print | `pi -p "…"` | 一次调用 | 只要最终文本 | `docs/cli-integration.md:14` |
| JSON | `pi --mode json "…" > events.jsonl` | 一次调用 | 要结构化过程事件 | `docs/cli-integration.md:15` |
| RPC | `pi --mode rpc --no-session` | 长驻 | 要双向控制 | `docs/cli-integration.md:16` |

四种模式共用同一个 agent、会话、资源与工具，且与工作目录、模型、工具、会话持久化正交（`docs/cli-integration.md:5,18`）。

### 3.2 Print

- 只写最终 assistant 文本，中间事件不暴露；错误写 stderr（`docs/cli-integration.md:24-32`）。
- 最终响应为 `error`/`aborted` 时退出码非零，适合 `if pi -p …; then` 这类判断（`docs/cli-integration.md:30`）。
- 非 TTY 自动进入该模式，所以 `git diff | pi --print "Review this change"` 不需要额外开关（`docs/cli.md:25-30`）。

### 3.3 JSON 事件流

- 第一行是 session header，随后是 agent/session 事件，跑完即退出，之后不再接受命令（`docs/json.md:3`、`docs/cli-integration.md:42-44`）。
- 帧格式是严格 JSONL：**只按 LF 切分**（容忍 CRLF），不要用 Node `readline`（它会把 U+2028/U+2029 当分隔符）；stdout 只放 JSONL，诊断走 stderr（`docs/json.md:13-19`）。
- `message_update` 在 wire 上是纯 delta（不含 SDK 的累积字段），用 `contentIndex` 定位块，最后用 `message_end.message` 整体替换（`docs/json.md:70-93`）。
- 事件族：`agent_start/agent_end/agent_settled`、`turn_start/turn_end`、`message_start/update/end`、`tool_execution_start/update/end`、`queue_update`、`entry_appended`、`compaction_start/end`、`auto_retry_*`、`summarization_retry_*` 等（`docs/json.md:52-126,161-180`）。
- 失败/中止的响应本身不导致非零退出码，成功与否要看事件（`docs/cli-integration.md:46`）；TypeScript 侧用导出的 `JsonAgentSessionEvent`（`docs/json.md:198-218`）。

### 3.4 RPC

- 协议就是 stdin/stdout 上的 JSONL，**不是 HTTP/WebSocket**；四类记录：stdin `command`、stdout `response`、stdout `session event`、双向 `extension_ui_*`（`docs/rpc.md:3,24-33`）。
- 命令异步处理，**必须按 `id` 关联而不是按顺序**；`prompt` 返回 `success:true` 只表示已受理（`started|queued|handled`），完成要等 `agent_settled`（`docs/rpc.md:36-71`）。
- 命令全集见 `docs/rpc-commands.md`：`prompt`、`steer`、`follow_up`、`abort`、`new_session`、`get_state`、`get_messages`、`set_model`、`cycle_model`、`compact`、`bash`、`export_html`、`switch_session`、`fork`、`clone`、`get_entries`、`get_tree`、`set_session_name`、`get_commands` 等（`docs/rpc-commands.md:36-42,493-509,689-717`）。`bash` 的结果在**下一次 prompt** 才进模型上下文。
- RPC 独有事件：`bash_execution_update`、`extension_error`；另有扩展 UI 子协议（`select/confirm/input/editor` 是请求-响应，`notify/setStatus/setWidget` 是通知）（`docs/json.md:182-194`、`docs/rpc-extension-ui.md:5-25`）。
- 退出：关闭子进程 stdin 触发有序退出；客户端要自己处理启动失败、意外退出、stderr、取消与超时，**不要解析 stderr**（`docs/rpc.md:89-95`）。
- Node/TS 优先用官方 `RpcClient`（`new RpcClient({ cliPath, args })` → `start()` → `onEvent()` → `promptAndWait()`），它需要指向一个**已构建**的 CLI（例子里是 `dist/cli.js`）；示例 `examples/rpc-client.ts:15-35`、`examples/rpc-extension-ui.ts`（`docs/cli-integration.md:72-80`）。
- 语言无关的 Python 管道客户端示例在 `docs/rpc.md:97-130`。

### 3.5 会话文件本身也是接口

`~/.pi/agent/sessions/**/*.jsonl` 有正式格式文档，可被任意语言直接解析或生成（`docs/session-format.md:1`）；`pi --export` 把它转成 HTML（`docs/cli.md:49`）。

---

## 4. 代码内嵌 SDK

- 入口：`createAgentSession()`（`@earendil-works/pi-coding-agent` 包根导入），另有 `createAgentSessionRuntime`、`SessionManager`、`DefaultResourceLoader`、`ModelRuntime`、`getModel`（`docs/sdk.md:3-8`、`src/index.ts`）。
- 最小骨架（默认发现 cwd 与 `~/.pi/agent` 的资源、设置、凭据）：

  ```ts
  import { createAgentSession, SessionManager } from "@earendil-works/pi-coding-agent";
  const { session } = await createAgentSession({ sessionManager: SessionManager.inMemory() });
  session.subscribe((e) => {
    if (e.type === "message_update" && e.assistantMessageEvent.type === "text_delta")
      process.stdout.write(e.assistantMessageEvent.delta);
  });
  await session.prompt("...");
  console.log(session.getLastAssistantText());
  session.dispose();
  ```

- `prompt()` 结束即一轮跑完；流式中再次 prompt 必须声明 `steer` 或 `followUp`，否则拒绝（`docs/sdk.md:64-70`）。
- 状态：`session.messages`、`.model`、`.thinkingLevel`、`.systemPrompt`、`.getActiveToolNames()`（`docs/sdk.md:30`）；会话持久化由 `SessionManager` 负责（树 + active leaf + compaction），直接改 `session.agent.state.messages` 不会替换持久化上下文（`docs/sdk.md:36-42`）。
- 可注入的边界：`modelRuntime/model/thinkingLevel/scopedModels`、`settingsManager`、`sessionManager`、`resourceLoader`、`tools/noTools/excludeTools/customTools`（`docs/sdk.md:100-108`）。
- **与 CLI 的关键差异**：CLI 默认加载的内置扩展 `codemode`、`tool_search`、MCP，SDK 会话默认**不加载**；需要把 `createCodemodeExtension()`、`createToolSearchExtension()`、`createMcpExtension()` 加进 `DefaultResourceLoader` 的 `extensionFactories`，并调用 `session.bindExtensions()`（`docs/sdk.md:116`、`docs/mcp.md:188`）。
- 14 个渐进示例：`examples/sdk/01-minimal.ts` … `14-codemode-mcp.ts`，覆盖工具收窄、内存会话、session runtime、codemode+MCP（`examples/sdk/README.md:9-24`）。
- 官方定位：SDK 不是一种 CLI 模式，而是把 agent 直接嵌进 Node/Bun 进程（`docs/cli-integration.md:7`）。

---

## 5. 自建产品：复用底层包、fork、实验性服务

### 5.1 fork / 改名 / 独立二进制

- `package.json` 的 `piConfig: { name, configDir }` 改 CLI 名与配置目录，顶层 `bin` 改可执行名，会影响横幅、配置路径与派生环境变量（`docs/cli-integration.md:82-95`）。
- `bun build --compile` 出 `dist/pi`（`pkgs/coding-agent/package.json` 的 `build:binary`）；release 资产由 `.github/workflows/build-binaries.yml` 生成。

### 5.2 可独立复用的包

| 包 | 定位 | 独立使用要点 | 证据 |
| --- | --- | --- | --- |
| `pi-ai` | 多供应商 LLM API 层 | 注册 provider → `models.getModel()` → `models.stream(model, context)` 逐事件；工具用 TypeBox schema | `pkgs/ai/README.md:105-170` |
| `pi-agent-core` | agent 运行时（工具/流式/队列/中断） | `new Agent({ initialState, streamFn })` + `agent.subscribe()` + `agent.prompt()`；低层还有 `agentLoop()` 生成器 | `pkgs/agent/README.md:17-43,539-566` |
| `pi-tui` | 差分渲染终端 UI 库 | `new ProcessTerminal()` + `TuiMainScreen`/`TuiAltScreen` + 组件树；pi 自己的 TUI 就用它 | `pkgs/tui/README.md:5-53` |
| `pi-durable` | 持久化会话运行时（**Experimental**） | `Harness.open()` → `root.submit()` → `submission.wait()` → `root.commit()`；存储可选 memory/JSONL/SQLite | `pkgs/durable/README.md:5,39-61,98-129` |
| `pi-session-backend-sqlite-node` | `node:sqlite` 会话后端 | `new SqliteSessionRepo({ directory, databaseFactory })`；单写者由宿主保证，无跨进程锁 | `pkgs/session-backends/sqlite-node/README.md:3-33` |
| `pi-mcp` | 不依赖官方 SDK 的 MCP 客户端 | `StdioTransport`/`StreamableHttpTransport` + `McpClient` + `listTools()/callTool()` | `pkgs/mcp/README.md:3-54,117-132` |
| `pi-codemode` | QuickJS 沙箱代码执行 | `new CodemodeSandbox({ tools })` + `sandbox.execute(code)`；只暴露注入的工具 | `pkgs/codemode/README.md:9-36,111-157` |
| `pi-telemetry` | 可观测性契约（无 exporter） | `telemetryContext.startSpan({name}, async (span) => …)`；参考实现 `InMemoryTelemetryContext` | `pkgs/telemetry/README.md:5-13,64-130` |
| `chord` | 组合式应用运行时（非 pi 专用） | facets/services + replicated state + delta + 打包加载；是 agent/durable/protocol/server/client/coding-agent 的共同依赖 | `pkgs/chord/README.md:5-7,109-148` |

### 5.3 实验性本地服务（`pi server` / `pi client`）

- 形态是**本机实验性服务**，不是公网服务：`pi-protocol` 做路由信封 + CBOR 编码 + 字节流分帧（协议版本 8，不做对端认证）；`pi-server` 自带 **Unix domain socket** 传输；`pi-client` 是 transport-neutral（注释提到可换 WebSocket，但仓库只提供 Unix 传输）（`pkgs/protocol/README.md:3-39`、`pkgs/server/README.md:3,27-75`、`pkgs/client/README.md:5-70`）。
- 门控：`PI_EXPERIMENTAL=1`（`src/core/experimental.ts:1-3`），`pi server` / `pi client` 走 `src/cli/experimental/`；`PI_SERVER_DIR` 覆盖 socket 目录（默认 `~/.pi/server`），`--server-id` 必须是小写 UUIDv4（`src/experimental/services/README.md:8-12`、`src/cli/experimental/commands/server.ts`）。
- 在 coding-agent 里它们是 **devDependencies**，且 `files` 排除了 `dist/client`、`dist/experimental`，即不随 npm 包与独立二进制发布；稳定版 TUI/CLI 不走这条路径（`pkgs/coding-agent/package.json:31-33,79-81`、`src/experimental/services/README.md:12`）。
- 上游生态里的成品形态：Slack/聊天自动化用 `earendil-works/pi-chat`，会话发布用 `badlogic/pi-share-hf`（根 `README.md:38,100`）。

---

## 6. 无人值守与隔离托管

- 文档把隔离分成三层（按强度）：① 直接用 OS 用户身份跑（只保护该用户本来就不能访问的东西）；② **整个 pi 进程**进容器/VM（通常最强）；③ pi 留在宿主，只把**内置工具**放进隔离环境（较窄，pi 自身与其他扩展仍在边界外）（`docs/security.md:13-17`）。
- 具体方案四种：Plain Docker、Docker Sandboxes（真凭据留宿主，由代理替换）、OpenShell（策略沙箱）、Gondolin 扩展（宿主跑 pi，内置工具与 `!` 命令进本地 micro-VM）（`docs/containerization.md:7-183`）。
- 注意事项：不要把宿主 `~/.pi/agent` 挂进容器（等于暴露凭据、设置、扩展与 session）；Gondolin 不是凭据边界，VM 内命令能继承宿主环境变量（`docs/containerization.md:20-28,157`）。
- 无人值守要显式给出的开关：`--approve` 或 `--no-approve`（trust）、`--offline`/`PI_OFFLINE=1`（关自动联网）、`-t/--tools` 与 `-ne/-ns/-np/--no-themes/-nc`（收窄工具与资源）、`--no-session` 或 `--session-dir`（会话落盘策略）（`docs/cli.md:96-99,119-127,194-213,235-240`）。
- 探活：`pi auth check --provider X --json` 退出码 0/1/2 对应 ready/not_ready/invalid；`pi mcp list` 会实际连接所有启用的 MCP server，异常时退出码 1（`docs/cli.md:299-301,323`）。
- 进程标记：CLI/RPC 入口设 `AI_AGENT=pi`、`PI_CODING_AGENT=true`，子进程继承；注入给 `bash`/`powershell` 工具的会话变量有 `PI_SESSION_ID`、`PI_SESSION_FILE`、`PI_PROVIDER`、`PI_MODEL`、`PI_REASONING_LEVEL`（**不注入**用户手敲的 `!`/`!!`）（`docs/environment-variables.md:13-49`）。
- 上游自己的实例：`.github/workflows/issue-analysis.yml:383-394` 用 `node packages/coding-agent/src/cli.ts -p --approve --session-dir <dir> --model … --thinking high "/is <issue-url>"`，之后 `--no-extensions --export` 导出会话 HTML 传 gist 并回帖。

---

## 附录 A：上游文档地图

上游 `docs/docs.json` 的分组（`docs/docs.json:1-208`）：

- **Get Started**：Overview、Quickstart、How Pi Works
- **Run Pi**：usage、models、sessions、security、containerization、llama-cpp、terminal-setup、shell-aliases、tmux、windows、termux
- **Customize Pi**：configuration、prompt-templates、skills、themes、packages、mcp
- **Build on Pi**：extensions、custom-provider、virtual-models、tui、cli-integration、sdk
- **Reference**：cli、slash-commands、settings、environment-variables、keybindings、providers、session-format、compaction、json、rpc、rpc-commands、rpc-extension-ui、message-types

## 附录 B：未核实清单

- `npx` 用法：上游文档完全没有（`bin` 只暴露 `pi`）。
- `https://pi.dev/install.sh` 的内部行为（装到哪、是否装独立二进制）与独立二进制的手动安装步骤：仓库内无文档。
- pnpm/yarn/bun 全局安装命令：只有代码级识别，无文档；Windows 上不支持 yarn/bun 自更新。
- `pi-server`/`pi-client`/`pi-protocol` 是否发布到 npm：services README 称被排除在 npm 包外，但未在 npm 上核实。
- 除实验性客户端 TUI 外，是否有 Web/编辑器插件消费 CBOR 协议：仓库内未见。
- `pi-ai` 的推荐入口（`createModels()` vs `builtinModels()`）：两份 README 写法不一致。
- 上游文档没有现成的 CI 配方（GitHub Actions / Docker CI 示例、超时与并发建议）。
