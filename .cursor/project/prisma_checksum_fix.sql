-- Prisma 迁移 checksum 修复脚本
-- 用途：当本地 migration.sql 被修改后，与数据库 _prisma_migrations 中的 checksum 不一致时
-- 使用方式：在确认表结构已正确的前提下，更新 _prisma_migrations 中的 checksum

-- ============================================================
-- 步骤 1：备份当前迁移记录（建议先执行）
-- ============================================================

-- 创建备份表（如果不存在）
CREATE TABLE IF NOT EXISTS "_prisma_migrations_backup" (
    LIKE "_prisma_migrations" INCLUDING ALL
);

-- 备份当前数据
INSERT INTO "_prisma_migrations_backup"
SELECT * FROM "_prisma_migrations"
ON CONFLICT DO NOTHING;

-- ============================================================
-- 步骤 2：查看当前迁移状态
-- ============================================================

-- 查询当前所有迁移及其 checksum
SELECT 
    "migration_name",
    "checksum",
    "finished_at",
    CASE 
        WHEN "migration_name" LIKE '%init%' THEN '建表初始化'
        WHEN "migration_name" LIKE '%device%' THEN '添加 deviceId'
        WHEN "migration_name" LIKE '%friend%' THEN '添加好友短码'
        ELSE '其他'
    END as "描述"
FROM "_prisma_migrations"
ORDER BY "finished_at";

-- ============================================================
-- 步骤 3：更新 checksum（根据实际情况修改）
-- ============================================================

-- ⚠️ 警告：以下 UPDATE 语句需要先计算正确的 checksum
-- checksum 计算方法：
-- 1. 在一个全新的空数据库上执行：npx prisma migrate deploy
-- 2. 查询得到的 checksum：SELECT migration_name, checksum FROM "_prisma_migrations"
-- 3. 将得到的 checksum 填入下面的 'xxx' 位置

-- 示例（请替换为实际值）：
-- UPDATE "_prisma_migrations"
-- SET "checksum" = '实际的checksum值'
-- WHERE "migration_name" = '20260324074615_init';

-- UPDATE "_prisma_migrations"
-- SET "checksum" = '实际的checksum值'
-- WHERE "migration_name" = '20260324000001_add_device_id_optional_password';

-- ============================================================
-- 步骤 4：验证修复结果
-- ============================================================

-- 重新检查 checksum 是否已更新
-- SELECT "migration_name", "checksum" FROM "_prisma_migrations" ORDER BY "finished_at";

-- ============================================================
-- 回滚方案（如果出现问题）
-- ============================================================

-- 如果需要回滚，从备份表恢复：
-- TRUNCATE "_prisma_migrations";
-- INSERT INTO "_prisma_migrations" SELECT * FROM "_prisma_migrations_backup";

-- 或者删除备份表重新开始：
-- DROP TABLE "_prisma_migrations_backup";
