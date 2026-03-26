# KeLeME 项目文档（`.cursor/project`）

本目录存放**与仓库协作、运维相关的说明**。业务与代码规范见仓库根目录 `AGENTS.md`、`CLAUDE.md`。

---

## 1. 仓库结构

| 路径 | 说明 |
|------|------|
| `ke_le_me/` | Flutter 客户端（主应用代码） |
| `backend/` | Node.js + Express + Prisma + PostgreSQL + Redis |

---

## 2. 当前能力摘要（与代码对齐）

### 2.1 饮水数据

- **本地优先**：`SharedPreferences` 存今日/月历聚合、连续天数等。
- **同步**：`UserProvider.loadProfile()` 完成后异步调用 `DrinkSyncService`：先处理待上传队列，再按当月范围拉取 `GET /api/drink-logs` 并与本地合并（策略：`max(local, remote)`）。
- **离线**：单条上传失败会入队，后续启动时 `bulkSync` 重试。

### 2.2 社区 / 关怀

- **成就墙**：已移除（无 `Achievement`/`AchievementBadge` UI）。
- **联系人**：通过 **6 位好友短码** 查找用户并 `POST /api/care/contacts`；`GET /api/care/friend-code`、`POST /rotate`、`GET /friend-lookup`（lookup 限流）。
- **HeartProvider**：优先从后端拉取联系人并合并本地备注/头像等展示字段。

### 2.3 客户端 HTTP

- `BackendApiService`：设备登录、JWT、refresh **并发合并**、`ensureAuthenticated` 使用 `/api/profile` 探活。

---

## 3. Prisma / 数据库运维

- **生产或已有库**：优先 `cd backend && npx prisma migrate deploy`（安全应用未执行迁移，不依赖 shadow DB）。
- **开发库需 `migrate dev` 且遇到 checksum 不一致**：勿随意改已应用的 `migration.sql`；必要时用元数据对齐（见 `prisma_checksum_fix.sql` 与 `calculate_prisma_checksums.sh`）。
- **约定**：新 schema 变更一律**新增**带时间戳的迁移目录，不修改已合并的迁移文件内容。

---

## 4. 本目录文件

| 文件 | 用途 |
|------|------|
| `README.md` | 本索引与现状摘要（**主文档**） |
| `prisma_checksum_fix.sql` | Prisma `_prisma_migrations.checksum` 修复 SQL 模板 |
| `calculate_prisma_checksums.sh` | 在空库上计算各迁移 checksum 的辅助脚本 |

---

## 5. 可选后续（未承诺）

- 关怀记录、关系类型/头像等是否上云与同步策略。
- 饮水同步观测：多设备回归、指标与日志。
- 短码模型是否升级为独立邀请表（一次性/作废/统计）。

---

*文档随仓库演进更新；历史过程说明已合并进本节，删除的旧版分散文档不再维护。*
