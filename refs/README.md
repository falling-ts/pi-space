# refs/ — 外部参考项目容器

本目录用于接入 **外部项目源码**，统一以 **git submodule（子项目）** 方式管理：
父仓库只记录每个子项目的 commit 指针，源码本身不入库，升级用 `git submodule update --remote`。

## 当前子项目

| 路径 | 上游 | 跟踪分支 |
| --- | --- | --- |
| `refs/pi/` | <https://github.com/earendil-works/pi> | `main` |

## 使用方式

```powershell
# 克隆父仓库后首次拉取所有参考项目
git submodule update --init --recursive

# 只拉取/更新 pi
git submodule update --init refs/pi

# 跟进上游 main（会把子模块工作区切到最新，父仓库出现指针变更）
git submodule update --remote refs/pi
git add refs/pi
git commit -m "chore(refs): bump pi to <sha>"

# 查看状态（+ 前缀表示工作区与记录的 commit 不一致）
git submodule status
```

## 新增一个参考项目

```powershell
git submodule add -b main <repo-url> refs/<name>
git commit -m "chore(refs): 接入 <name>"
```

同时在 `AGENTS.md` 的目录表和本文件的表格里补一行。

## 规则

- `refs/*` 是 **只读镜像**：不要在其中提交、不要改动其工作区；需要改代码就复制到 `.agents/scratch/`。
- 升级子模块指针时，提交信息里写清上游 commit 与升级原因。
