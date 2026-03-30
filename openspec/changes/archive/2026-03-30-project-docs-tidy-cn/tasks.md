## 1. 文档清单与重命名（`.cursor/project`）

- [x] 1.1 全文检索旧文件名，列出 `.cursor/project` 外引用点（含 `AGENTS.md`、`CLAUDE.md`、`.cursor/rules`、`backend/` 脚本注释等）
- [x] 1.2 将 `vps_backend_deployment_plan.md` 重命名为 `VPS后端部署规划.md`
- [x] 1.3 将 `vps_backend_deploy_steps.md` 重命名为 `VPS后端部署步骤.md`
- [x] 1.4 将 `backend_deployment_standard.md` 重命名为 `后端部署规范.md`
- [x] 1.5 将 `ke_le_me_product_documentation.md` 重命名为 `渴了么产品文档.md`
- [x] 1.6 在 `.cursor/project/README.md` 增加「旧文件名 → 新文件名」迁移表（可选，推荐）

## 2. 全局引用与根文档

- [x] 2.1 更新 `AGENTS.md`、`CLAUDE.md` 中指向上述文档的链接或路径描述
- [x] 2.2 更新仓库内其余 Markdown / Shell 中对旧文件名的引用；确认不误改 `openspec/**` 中需保留的历史叙述
- [x] 2.3 核对 `prisma_checksum_fix.sql`、`calculate_prisma_checksums.sh` 与 `VPS后端部署步骤.md` 等是否仍需要；若删除，在任务或说明中写明理由 — **结论：保留**；`README.md` §4 Prisma 运维仍引用，未删除。

## 3. 代码精简（`flutter/` / 必要时 `backend/`）

- [x] 3.1 `flutter/`：移除明显未使用 import、死代码、大块注释代码（不改行为）— 顺带消除 `backend_api_service.dart`、`ai_service.dart` 上 `flutter analyze` 的 info，使分析干净
- [x] 3.2 `backend/`：同上（若本变更触及）— **未改** `backend/` 源码

## 4. 验收

- [x] 4.1 若修改了 `flutter/lib/**`：在 `flutter/` 执行 `flutter analyze` 与 `flutter test`，均通过
- [x] 4.2 对旧主文件名做检索，确认无未处理的有效断链（或仅剩迁移说明）
