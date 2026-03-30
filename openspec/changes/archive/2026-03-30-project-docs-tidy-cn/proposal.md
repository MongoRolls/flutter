## Why

`.cursor/project` 等处长期沿用英文档名（如 `vps_backend_*`、`backend_deployment_standard`），与「项目技术文档集中存放、中文沟通」的约定不一致；交叉引用与脚本路径易陈旧。需在**不改动 `openspec/**` 文件命名与结构**的前提下，统一中文档名、清理确认无用的文件，并对 `flutter/`、`backend/` 做有限代码整理，降低维护成本。

## What Changes

- 将 `.cursor/project` 内所列英文技术文档重命名为**有意义的中文文件名**，并**全局更新**仓库内 Markdown、脚本、Agent 说明中对旧路径的引用。
- 在 `.cursor/project/README.md`（或等价索引）中可选增加**旧文件名 → 新文件名**迁移说明，缓解外部书签失效。
- 删除经确认**无用**的文档或文件；删除前核对 CI、部署脚本与文档引用（含 `prisma_checksum_fix.sql`、`calculate_prisma_checksums.sh` 等是否仍被 `VPS` 部署类文档引用）。
- 在 `flutter/` 与必要时 `backend/` 内做**有限**简化：移除明显死代码、未使用 import、注释块；**不**做大范围重构或行为变更。
- **不包含**：`openspec/**` 内文件的英文化重命名或随意删除；`web/` 默认不在范围；依赖大版本升级。
- 根目录 **`AGENTS.md`、`CLAUDE.md` 保持英文文件名**（工具约定）；仅更新其中指向 `.cursor/project` 的链接文案或路径。

## Capabilities

### New Capabilities

- `repo-project-docs`: 约定 `.cursor/project` 下用户可读技术文档的中文命名、交叉引用完整性、可选迁移说明；以及在本变更触及 `flutter/` 或 `backend/` 代码时的质量门禁（`flutter analyze` / `flutter test`）。

### Modified Capabilities

- （无）本变更为仓库卫生与文档约定，不改变 `openspec/specs/` 中既有产品能力需求。

## Impact

- **路径**：`.cursor/project/**`（重命名与内容内链）、根目录 `AGENTS.md`、`CLAUDE.md`（链接更新）。
- **代码**：`flutter/lib/**` 与必要时 `backend/**` 局部删减与整理。
- **不包含**：`web/`；`openspec/**` 内除本变更目录 `openspec/changes/project-docs-tidy-cn/` 外的树结构。
