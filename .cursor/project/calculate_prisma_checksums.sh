#!/bin/bash
# Prisma Migration Checksum 自动计算脚本
# 用途：在空数据库上运行所有迁移，获取正确的 checksum 值

set -e

echo "🔧 Prisma Migration Checksum 计算工具"
echo "======================================"

# 配置（可修改）
EMPTY_DB_NAME="prisma_checksum_temp"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"

cd "$(dirname "$0")/../.."  # 回到项目根目录
BACKEND_DIR="backend"

echo ""
echo "📋 步骤说明："
echo "1. 创建一个临时空数据库"
echo "2. 运行 prisma migrate deploy"
echo "3. 查询并显示所有迁移的 checksum"
echo "4. 输出可用于修复的 SQL 语句"
echo ""

# 检查必要命令
if ! command -v psql &> /dev/null; then
    echo "❌ 错误：未找到 psql 命令，请确保 PostgreSQL 客户端已安装"
    exit 1
fi

if ! command -v npx &> /dev/null; then
    echo "❌ 错误：未找到 npx 命令，请确保 Node.js 和 npm 已安装"
    exit 1
fi

# 询问数据库连接信息
echo "📝 请输入 PostgreSQL 连接信息（用于创建临时数据库）："
read -p "用户名 [postgres]: " input_user
POSTGRES_USER="${input_user:-$POSTGRES_USER}"

read -p "主机 [localhost]: " input_host
POSTGRES_HOST="${input_host:-$POSTGRES_HOST}"

read -p "端口 [5432]: " input_port
POSTGRES_PORT="${input_port:-$POSTGRES_PORT}"

read -s -p "密码: " POSTGRES_PASSWORD
echo ""

# 构建连接字符串
export PGHOST="$POSTGRES_HOST"
export PGPORT="$POSTGRES_PORT"
export PGUSER="$POSTGRES_USER"
export PGPASSWORD="$POSTGRES_PASSWORD"

echo ""
echo "🗄️  创建临时数据库: $EMPTY_DB_NAME"

# 删除可能存在的旧临时数据库
psql -d postgres -c "DROP DATABASE IF EXISTS \"$EMPTY_DB_NAME\";" 2>/dev/null || true

# 创建新临时数据库
psql -d postgres -c "CREATE DATABASE \"$EMPTY_DB_NAME\";"

echo "✅ 临时数据库创建成功"

# 设置 DATABASE_URL 并运行迁移
cd "$BACKEND_DIR"
export DATABASE_URL="postgresql://$POSTGRES_USER:${POSTGRES_PASSWORD}@$POSTGRES_HOST:$POSTGRES_PORT/$EMPTY_DB_NAME"

echo ""
echo "🚀 运行 Prisma Migrate Deploy..."
npx prisma migrate deploy

echo ""
echo "📊 查询迁移 checksum..."
echo ""

# 查询并格式化输出结果
checksum_result=$(psql -d "$DATABASE_URL" -t -A -F"|" -c "
SELECT 
    migration_name,
    checksum,
    finished_at
FROM \"_prisma_migrations\"
ORDER BY finished_at;
")

echo "======================================"
echo "迁移名称 | Checksum | 完成时间"
echo "======================================"
echo "$checksum_result" | while IFS='|' read -r name checksum finished; do
    if [ -n "$name" ]; then
        echo "$name"
        echo "  Checksum: $checksum"
        echo "  完成时间: $finished"
        echo ""
    fi
done

echo ""
echo "📝 生成的修复 SQL 语句（可直接复制使用）："
echo "======================================"
echo ""

# 生成修复 SQL
echo "-- 在开发/生产数据库上执行以下 SQL："
echo ""

while IFS='|' read -r name checksum finished; do
    if [ -n "$name" ] && [ -n "$checksum" ]; then
        echo "UPDATE \"_prisma_migrations\""
        echo "SET \"checksum\" = '$checksum'"
        echo "WHERE \"migration_name\" = '$name';"
        echo ""
    fi
done <<< "$checksum_result"

# 清理临时数据库
echo ""
echo "🧹 清理临时数据库..."
cd ..
psql -d postgres -c "DROP DATABASE IF EXISTS \"$EMPTY_DB_NAME\";" 2>/dev/null || true

echo ""
echo "✅ 完成！"
echo ""
echo "💡 使用说明："
echo "1. 将上面生成的 UPDATE 语句在需要修复的数据库上执行"
echo "2. 执行前建议先备份 _prisma_migrations 表"
echo "3. 执行后运行 'npx prisma migrate status' 验证"
echo ""
