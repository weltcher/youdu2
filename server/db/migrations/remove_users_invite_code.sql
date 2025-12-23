-- 删除 users 表中不再需要的邀请码相关字段
-- 注意：执行前请确保 invite_code_usages 表已经有完整的数据

-- 删除 invite_code 字段（用户自己的邀请码，不再需要）
ALTER TABLE users DROP COLUMN IF EXISTS invite_code;

-- 删除 invited_by_code 字段（用户注册时使用的邀请码，改为从关联表查询）
ALTER TABLE users DROP COLUMN IF EXISTS invited_by_code;
