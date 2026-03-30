## ADDED Requirements

### Requirement: 项目技术文档中文档名

`.cursor/project` 目录下、面向贡献者阅读的技术说明类 Markdown 文件 MUST 使用**有意义的中文文件名**（示例：`VPS后端部署步骤.md`、`后端部署规范.md`）。`openspec/**` 目录不在本要求范围内。

#### Scenario: 重命名完成后可读性

- **WHEN** 贡献者浏览 `.cursor/project` 目录
- **THEN** 主要部署与产品类说明文档以中文文件名呈现，且与 `proposal.md` 中「候选重命名」表一致或等价

### Requirement: 交叉引用与旧路径清理

完成重命名后，仓库内（**不含** `openspec/**` 下既有规范树中对旧名的刻意保留）指向旧英文文件名的链接、脚本路径 MUST 已更新为新路径；或已在 `.cursor/project/README.md` 中说明迁移关系。

#### Scenario: 无残留断链

- **WHEN** 在仓库根目录对旧主文件名（如 `vps_backend_deploy_steps.md`）做全文检索
- **THEN** 不存在仍指向该文件名的有效引用，或仅剩迁移说明 / `openspec` 排除范围内的条目

### Requirement: Flutter 变更质量门禁

若本变更修改了 `flutter/` 下任何 Dart 源码，则 MUST 在 `flutter/` 目录执行 `flutter analyze` 与 `flutter test` 且均成功。

#### Scenario: 分析测试通过

- **WHEN** 变更包含对 `flutter/lib/**` 的编辑且进入交付
- **THEN** `flutter analyze` 与 `flutter test` 退出码均为 0

### Requirement: 删除与代码简化可复核

删除文件或删减代码时，MUST 在变更说明或 `tasks.md` 勾选记录中可追溯到理由；删除部署相关脚本或 SQL 前 MUST 确认未被文档或其它脚本引用。

#### Scenario: 删除有据

- **WHEN** 某文件从仓库移除
- **THEN** 任务清单或提交说明中载明删除原因，且 `grep`/文档检索无未替换的关键依赖
