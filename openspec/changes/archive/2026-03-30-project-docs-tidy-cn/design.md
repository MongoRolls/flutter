## Context

KeLeME  monorepo 将项目相关 Markdown 约定放在 `.cursor/project`。当前存在英文档名与中文协作习惯不一致、链与脚本可能指向旧名等问题。用户确认：**根目录 `AGENTS.md`、`CLAUDE.md` 保持英文文件名**；**仅整理 `.cursor/project` 及上述根文档中的引用**；OpenSpec 规范树不重命名、不删。

## Goals / Non-Goals

**Goals:**

- 将下列文件重命名为中文主文件名，并全局替换引用（候选表与 `proposal.md` 一致）：
  - `vps_backend_deployment_plan.md` → `VPS后端部署规划.md`
  - `vps_backend_deploy_steps.md` → `VPS后端部署步骤.md`
  - `backend_deployment_standard.md` → `后端部署规范.md`
  - `ke_le_me_product_documentation.md` → `渴了么产品文档.md`
- **保留** `.cursor/project/README.md` 英文名（常见索引约定）；在其中增加简短「旧名 → 新名」表可选但推荐。
- 删除文件前对照 `vps_*` 类文档与部署说明，确认 `prisma_checksum_fix.sql`、`calculate_prisma_checksums.sh` 是否仍需要。

**Non-Goals:**

- 不修改 `openspec/specs/**`、`openspec/changes/**`（除本变更 `project-docs-tidy-cn` 工件）的命名与结构。
- 不默认修改 `web/`。
- 不为「简洁」重写业务层或引入新抽象。

## Decisions

| 决策 | 选择 | 理由 |
|------|------|------|
| 根目录 Agent 文档 | 保持 `AGENTS.md`、`CLAUDE.md` 英文名 | 工具与社区惯例；仅更新内部链接 |
| `.cursor/project/README.md` | 保留英文名 | 用户待确认项采用「保留」以降低破坏工具假设的风险 |
| 全局替换范围 | `rg`/`grep` 全仓，排除 `openspec/` 下非本变更路径时按 spec 仅替换 `.cursor/project` 与根文档 | 避免误改 OpenSpec 历史归档中的路径叙述；若归档中需指向新文档名，单独评估 |
| 代码简化深度 | 优先：未使用 import、注释掉的大块、明显 unreachable；次选：小范围重复提取 | 控制回归风险 |

## Risks / Trade-offs

- **[Risk] 全局替换误伤字符串常量** → **Mitigation**：按路径分步替换；先改 `.md` 与 shell，再 Dart（谨慎）。
- **[Risk] 外部书签失效** → **Mitigation**：`README.md` 迁移表。
- **[Risk] 删错部署脚本** → **Mitigation**：删除前全文搜索引用并与 `VPS后端部署步骤.md` 对照。

## Migration Plan

1. 重命名 `.cursor/project` 下四个 Markdown 文件。
2. 更新 `AGENTS.md`、`CLAUDE.md`、`.cursor/project/README.md` 及其它仓库内引用。
3. 可选：在 `README.md` 增加迁移一行表。
4. 执行代码精简与 `flutter analyze` / `flutter test`（若触及 Flutter）。

## Open Questions

- `git status` 中已标记删除但未提交的旧 `.cursor/project/*.md`：在合并本变更时一并清理工作区，避免重复。
- 若未来要求「目录内零英文档名」，再将 `README.md` 改为 `说明.md` 并更新引用。
