# AGENTS.md — pi agent 专属空间

本仓库是 **pi agent 的专属工作空间**（workspace root：`D:\AI\pi-space`）。

任何在此目录下工作的 agent / 协作者，开始任务前先读完本文件。

---

## 1. 空间定位

- **目标**：围绕上游项目 `pi`（<https://github.com/earendil-works/pi>）做源码研读、实验与文档沉淀。
- **原则**：上游源码 **只读参考**；本空间只入库自己的产物（文档、配置、实验代码）。
- **边界**：不在本空间内发布或修改上游代码；需要改动上游时，先在下游验证，再单独向上游提 PR。

## 2. 目录约定

| 路径 | 用途 | 入库策略 |
| --- | --- | --- |
| `AGENTS.md` | 本文件：空间规则与工作约定 | ✅ 入库 |
| `README.md` | 仓库说明；**本仓库唯一的 README** | ✅ 入库 |
| `pi.cmd` `pi.ps1` `pi` | 本地 pi 启动器（cmd / PowerShell / Git Bash），从源码直跑 | ✅ 入库 |
| `.gitattributes` | 行尾约定：`*.cmd` 保持 CRLF，根 `pi` 保持 LF | ✅ 入库 |
| `.agents/` | agent 运行期状态：临时脚本、草稿、缓存、任务中间产物 | 仅 `.gitkeep`，运行期内容忽略 |
| `docs/` | 正式文档：调研笔记、架构分析、实验记录、决策记录 | 仅 `.gitkeep`，文档入库 |
| `refs/` | 外部参考项目容器 | 仅 `.gitkeep` |
| `refs/pi/` | 上游 `pi` 源码，以 **git submodule** 形式接入 | 父仓库只记录 commit 指针 |
| `.gitignore` | 忽略规则（构建产物、环境密钥、编辑器/系统垃圾、agent 运行期状态） | ✅ 入库 |
| `.gitmodules` | 子项目（submodule）声明：路径、URL、跟踪分支 | ✅ 入库 |

## 3. 硬性规则

1. **不要修改 `refs/pi/` 的工作区**，也不要在这个子模块里提交。它是上游镜像，需要试验时把代码复制到 `.agents/scratch/` 或 `docs/` 下再改。
2. **改动子模块指针必须显式提交**：`git -C refs/pi fetch` 后父仓库会看到 `refs/pi` 有新 commit，只有在确认新 commit 可用后才 `git add refs/pi` 并在提交信息里写明上游 commit 与原因。
3. **不要在父仓库里新增重名的顶层目录**；新增顶层内容前先更新本文件的目录表。
4. **README 只在仓库根目录存在**（`README.md`）：子目录一律不新建 README，目录用途统一写在根 `README.md` 与本文件里；空目录用 `.gitkeep` 占位。
5. 文档放在 `docs/`，一个主题一个文件，命名用 `短横线小写.md`（例：`pi-architecture.md`）。
6. 提交信息用 `type(scope): summary`，例：`docs(pi): 记录 session 生命周期`。
7. 临时产物写入 `.agents/tmp/`（已被忽略），不要污染工作区状态。

## 4. 常用命令

```powershell
# 首次检出（或换了机器）后拉取子模块
git submodule update --init --recursive

# 跟进上游 main 分支最新提交
git submodule update --remote refs/pi
git add refs/pi && git commit -m "chore(refs): bump pi to <sha>"

# 只做事后核对，不改变指针
git -C refs/pi fetch origin
git -C refs/pi log --oneline --decorate -10 origin/main

# 查看当前记录的指针
git submodule status

# 在仓库根运行本地 pi（源码直跑，启动器见根目录 pi.cmd / pi.ps1 / pi）
pi --version        # cmd.exe：cmd 会搜索当前目录
.\pi --version      # PowerShell：pwsh 不搜索当前目录，必须带 .\
./pi --version      # Git Bash

# 重建本地 pi 工作副本（.agents/scratch/ 不入库，需在换机器或清理后重做）
git submodule update --init refs/pi
robocopy refs\pi .agents\scratch\pi /E /XD .git    # 退出码 0-7 均视为成功
cd .agents\scratch\pi
npm.cmd ci --ignore-scripts                        # 必须用 npm.cmd，见下
npm.cmd run hydrate:model-data                     # 联网生成 providers/data（上游 gitignore 的生成物）
```

注意：本机继承的 `npm_*` 环境变量会让 `npm`（`npm.ps1`）走错路径并报 `Unknown command: "pm"`，务必用 `npm.cmd`。

## 5. 当前状态

- 本空间远程仓库：`origin` → `git@github.com:falling-ts/pi-space.git`（分支 `main`）
- 子模块：`refs/pi` → <https://github.com/earendil-works/pi>（跟踪分支 `main`）
- 本地 pi 启动器：根目录 `pi.cmd` / `pi.ps1` / `pi`，运行的是 `.agents/scratch/pi` 这份工作副本（上游 `1b347794` 的复制），未改动任何用户/系统 PATH
- 仓库说明见 [`README.md`](README.md)（子目录不含 README）
