# pi-space

pi agent 的专属工作空间：围绕上游 [pi](https://github.com/earendil-works/pi) 做源码研读、实验与文档沉淀。

- 工作规则见 [AGENTS.md](AGENTS.md) —— agent 与协作者开始任务前先读。
- 上游源码以 **git submodule** 挂在 `refs/pi/`，父仓库只记录 commit 指针，不存上游代码。

## 目录结构

| 路径 | 用途 | 入库 |
| --- | --- | --- |
| `AGENTS.md` | 空间规则与工作约定 | ✅ |
| `README.md` | 本文件；**仓库唯一的 README** | ✅ |
| `pi.cmd` `pi.ps1` `pi` | 本地 pi 启动器：从源码直跑上游 pi | ✅ |
| `.gitattributes` | 行尾约定：`*.cmd` 保持 CRLF，根 `pi` 保持 LF | ✅ |
| `.agents/` | agent 运行期状态：`tmp/` `scratch/` `cache/` `sessions/` | 仅 `.gitkeep` |
| `docs/` | 正式文档：调研笔记、架构分析、实验记录、决策记录 | 仅 `.gitkeep` |
| `refs/` | 外部参考项目容器 | 仅 `.gitkeep` |
| `refs/pi/` | 上游 pi 源码（submodule，**只读镜像**） | 仅 commit 指针 |
| `.gitignore` | 忽略规则：构建产物、日志、`.env` 与密钥、编辑器/系统垃圾、agent 运行期状态 | ✅ |
| `.gitmodules` | 子项目（submodule）声明：路径、URL、跟踪分支 | ✅ |

约定：**README 只在仓库根目录存在**，子目录不新建 README；目录用途统一记在本文件与 `AGENTS.md`。

## 子项目：refs/pi

| 路径 | 上游 | 跟踪分支 |
| --- | --- | --- |
| `refs/pi/` | <https://github.com/earendil-works/pi> | `main` |

```powershell
git submodule update --init --recursive   # 换机器后首次拉取
git submodule update --remote refs/pi     # 跟进上游 main
git add refs/pi && git commit -m "chore(refs): bump pi to <sha>"
git submodule status                      # 查看当前指针
```

新增一个参考项目：

```powershell
git submodule add -b main <repo-url> refs/<name>
```

`refs/*` 为只读镜像：不要在其中提交、不要改动其工作区；需要改代码请复制到 `.agents/scratch/`。

## 本地 pi 命令

仓库根目录放了三个启动器，从源码直跑上游 pi（等价于上游 `pi-test.ps1` 的调用方式：`node --import <source-resolver> packages/coding-agent/src/cli.ts`，不编译、不安装到全局）：

| 文件 | 由谁使用 | 输入 |
| --- | --- | --- |
| `pi.cmd` | cmd.exe 与 PowerShell / pwsh（经 `PATHEXT` 解析） | `pi` |
| `pi.ps1` | 仅由 `pi.cmd` 调用（自带 `-ExecutionPolicy Bypass`） | 不直接用 |
| `pi` | Git Bash / MSYS | `pi` |

**仓库根 `D:\AI\pi-space` 已加入用户 PATH**（`HKCU\Environment`，仅用户级，未动系统 PATH），所以任意目录下裸 `pi` 都能用，不限于仓库根。若在旧终端里 `pi` 找不到，重开终端让 PATH 生效即可；换机器后需重新添加该条目。

它们启动的是 `.agents/scratch/pi` 这份本地工作副本，`refs/pi` 始终保持只读。副本不入库，换机器或清理 `.agents/` 后按下面步骤重建：

```powershell
git submodule update --init refs/pi
robocopy refs\pi .agents\scratch\pi /E /XD .git    # 退出码 0-7 都算成功
cd .agents\scratch\pi
npm.cmd ci --ignore-scripts
npm.cmd run hydrate:model-data    # 生成 packages/ai/src/providers/data/
```

两个坑：

- **必须用 `npm.cmd` 而不是 `npm`**：本机继承的 `npm_*` 环境变量（如 `npm_execpath` 指向 pnpm store）会让 `npm.ps1` 走错路径，报 `Unknown command: "pm"`。
- **`hydrate:model-data` 必不可少且需要联网**：上游把 `packages/ai/src/providers/data/` 写进了 `.gitignore`，它是生成物；缺它时任何 `pi` 调用都会以 `ERR_MODULE_NOT_FOUND: .../providers/data/.manifest.json` 失败。该命令从 models.dev / OpenRouter / Vercel AI Gateway / Radius / NVIDIA NIM 拉取模型目录（`--strict`，任一失败即报错）。

## 文档计划（docs/）

| 文件 | 主题 |
| --- | --- |
| `pi-overview.md` | 上游 pi 的定位、包结构与入口 |
| `pi-architecture.md` | 核心架构：agent loop、工具系统、会话模型 |
| `pi-dev-setup.md` | 本地构建 / 运行 / 调试 pi 的步骤 |
| `decisions.md` | 本空间关键决策记录（含参考项目接入方式） |

文档约定：结论先行；与上游版本强相关的结论注明 `upstream: <sha>`。
