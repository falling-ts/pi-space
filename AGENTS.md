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
| `.agents/` | agent 运行期状态：临时脚本、草稿、缓存、任务中间产物 | 目录与说明入库，运行期内容忽略 |
| `docs/` | 正式文档：调研笔记、架构分析、实验记录、决策记录 | ✅ 入库 |
| `refs/` | 外部参考项目容器 | 容器与说明入库 |
| `refs/pi/` | 上游 `pi` 源码，以 **git submodule** 形式接入 | 父仓库只记录 commit 指针 |
| `.gitignore` | 忽略规则（构建产物、环境密钥、编辑器/系统垃圾、agent 运行期状态） | ✅ 入库 |
| `.gitmodules` | 子项目（submodule）声明：路径、URL、跟踪分支 | ✅ 入库 |

## 3. 硬性规则

1. **不要修改 `refs/pi/` 的工作区**，也不要在这个子模块里提交。它是上游镜像，需要试验时把代码复制到 `.agents/scratch/` 或 `docs/` 下再改。
2. **改动子模块指针必须显式提交**：`git -C refs/pi fetch` 后父仓库会看到 `refs/pi` 有新 commit，只有在确认新 commit 可用后才 `git add refs/pi` 并在提交信息里写明上游 commit 与原因。
3. **不要在父仓库里新增重名的顶层目录**；新增顶层内容前先更新本文件的目录表。
4. 文档放在 `docs/`，一个主题一个文件，命名用 `短横线小写.md`（例：`pi-architecture.md`）。
5. 提交信息用 `type(scope): summary`，例：`docs(pi): 记录 session 生命周期`。
6. 临时产物写入 `.agents/tmp/`（已被忽略），不要污染工作区状态。

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
```

## 5. 当前状态

- 本空间远程仓库：`origin` → `git@github.com:falling-ts/pi-space.git`（分支 `main`）
- 子模块：`refs/pi` → <https://github.com/earendil-works/pi>（跟踪分支 `main`）
- 详细说明见 [`refs/README.md`](refs/README.md)、[`docs/README.md`](docs/README.md)、[`.agents/README.md`](.agents/README.md)
