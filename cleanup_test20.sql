-- 清理脚本：删除或修改包含 test20 的用户记录
-- ⚠️ 警告：执行前请先运行 diagnose_test20.sql 确认问题
-- 数据库：youdu_db

-- 方案1：查看要删除的记录（安全查看）
SELECT 'username字段中的test20' as description, id, username, phone, email, created_at
FROM users
WHERE username = 'test20'
UNION ALL
SELECT 'phone字段中的test20' as description, id, username, phone, email, created_at
FROM users
WHERE phone = 'test20'
UNION ALL
SELECT 'email字段中的test20' as description, id, username, phone, email, created_at
FROM users
WHERE email = 'test20';

-- ====================================================================
-- ⚠️ 以下是实际删除/修改操作，执行前请仔细确认！
-- ====================================================================

-- 方案2：删除 username 为 test20 的用户（取消注释后执行）
-- DELETE FROM users WHERE username = 'test20';

-- 方案3：将 phone 字段中的 test20 设为 NULL（如果是误用）
-- UPDATE users SET phone = NULL WHERE phone = 'test20';

-- 方案4：将 email 字段中的 test20 设为 NULL（如果是误用）
-- UPDATE users SET email = NULL WHERE email = 'test20';

-- 方案5：查看最近创建的可疑用户
-- SELECT id, username, phone, email, created_at
-- FROM users
-- WHERE created_at > NOW() - INTERVAL '1 day'
-- ORDER BY created_at DESC;

