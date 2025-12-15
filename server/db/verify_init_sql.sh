#!/bin/bash
# 验证 init.sql 文件的完整性和正确性

echo "========================================="
echo "验证 init.sql 文件"
echo "========================================="
echo ""

# 检查文件是否存在
if [ ! -f "server/db/init.sql" ]; then
    echo "❌ 错误: init.sql 文件不存在"
    exit 1
fi

echo "✓ 文件存在"

# 检查文件编码
ENCODING=$(file -b --mime-encoding server/db/init.sql)
echo "✓ 文件编码: $ENCODING"

if [ "$ENCODING" != "utf-8" ]; then
    echo "⚠️  警告: 文件编码不是 UTF-8"
fi

# 统计表数量
TABLE_COUNT=$(grep -c "CREATE TABLE" server/db/init.sql)
echo "✓ 表数量: $TABLE_COUNT"

# 统计 COPY 语句数量
COPY_COUNT=$(grep -c "^COPY public\." server/db/init.sql)
echo "✓ COPY 语句数量: $COPY_COUNT"

if [ "$COPY_COUNT" -eq 1 ]; then
    echo "  ✓ 只保留了 users 表的数据"
else
    echo "  ⚠️  警告: 发现 $COPY_COUNT 个 COPY 语句"
fi

# 检查管理员账号
if grep -q "系统管理员" server/db/init.sql; then
    echo "✓ 管理员账号已添加"
    echo ""
    echo "管理员账号信息："
    echo "  用户名: admin"
    echo "  密码: wq123123"
    echo "  邀请码: 666666"
    echo "  邮箱: admin@youdu.com"
else
    echo "❌ 错误: 未找到管理员账号"
    exit 1
fi

# 检查密码哈希
if grep -q '\$2a\$10\$NLWeG7ftdh0YSWzkpnhhRO0SLvnf9Svm2J260hTTWVvdtxdc35./i' server/db/init.sql; then
    echo "✓ 管理员密码哈希正确"
else
    echo "❌ 错误: 管理员密码哈希不正确"
    exit 1
fi

# 检查邀请码
if grep -q "666666" server/db/init.sql; then
    echo "✓ 邀请码 666666 已设置"
else
    echo "❌ 错误: 未找到邀请码 666666"
    exit 1
fi

# 统计用户数量
USER_COUNT=$(grep -c "^[0-9]" server/db/init.sql | head -1)
echo "✓ 用户数据行数: 约 $USER_COUNT 行"

echo ""
echo "========================================="
echo "验证完成！"
echo "========================================="
echo ""
echo "文件路径: server/db/init.sql"
echo "文件大小: $(du -h server/db/init.sql | cut -f1)"
echo ""
echo "导入命令:"
echo "  psql -U postgres -d youdu_db -f server/db/init.sql"
echo ""
