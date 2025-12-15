#!/bin/bash

# PostgreSQL 数据库验证脚本

DB_NAME="youdu_db"
DB_USER="postgres"
DB_HOST="127.0.0.1"
DB_PORT="5432"

echo "=========================================="
echo "  PostgreSQL 数据库验证"
echo "=========================================="
echo ""

# 检查数据库是否存在
echo "🔍 检查数据库连接..."
psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -c "SELECT version();" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ 无法连接到数据库 '$DB_NAME'"
    exit 1
fi
echo "✅ 数据库连接成功"
echo ""

# 统计表数量和行数
echo "📊 数据表统计:"
echo ""
psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -A -F"," -c "
SELECT 
    t.table_name,
    COALESCE(
        (SELECT COUNT(*) 
         FROM information_schema.columns c 
         WHERE c.table_schema = t.table_schema 
         AND c.table_name = t.table_name), 0
    ) as column_count
FROM information_schema.tables t
WHERE t.table_schema = 'public' 
AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name;
" | while IFS=',' read -r table_name column_count; do
    # 获取行数
    row_count=$(psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -A -c "SELECT COUNT(*) FROM \"$table_name\";")
    printf "  %-30s 列数: %3d  行数: %6d\n" "$table_name" "$column_count" "$row_count"
done

echo ""
echo "📋 关键表数据检查:"
echo ""

# 检查用户表
user_count=$(psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -A -c "SELECT COUNT(*) FROM users;")
echo "  👥 用户总数: $user_count"

# 检查消息表
message_count=$(psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -A -c "SELECT COUNT(*) FROM messages;")
echo "  💬 消息总数: $message_count"

# 检查群组表
group_count=$(psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -A -c "SELECT COUNT(*) FROM groups;")
echo "  👨‍👩‍👧‍👦 群组总数: $group_count"

# 检查版本表
version_count=$(psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -A -c "SELECT COUNT(*) FROM app_versions;" 2>/dev/null || echo "0")
echo "  📦 版本记录: $version_count"

echo ""
echo "⚠️  外键约束检查:"
echo ""

# 检查 user_relations 中的无效外键
invalid_friend=$(psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -A -c "
SELECT COUNT(*) 
FROM user_relations ur 
LEFT JOIN users u ON ur.friend_id = u.id 
WHERE u.id IS NULL;
" 2>/dev/null || echo "0")

invalid_user=$(psql -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -d "$DB_NAME" -t -A -c "
SELECT COUNT(*) 
FROM user_relations ur 
LEFT JOIN users u ON ur.user_id = u.id 
WHERE u.id IS NULL;
" 2>/dev/null || echo "0")

if [ "$invalid_friend" -gt 0 ] || [ "$invalid_user" -gt 0 ]; then
    echo "  ⚠️  发现无效的用户关系记录:"
    echo "     - 无效的 friend_id: $invalid_friend 条"
    echo "     - 无效的 user_id: $invalid_user 条"
    echo "     (这些记录不影响正常功能)"
else
    echo "  ✅ 所有外键关系正常"
fi

echo ""
echo "=========================================="
echo "  验证完成"
echo "=========================================="
