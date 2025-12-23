-- 为 users 表添加备注字段
ALTER TABLE users ADD COLUMN IF NOT EXISTS remark VARCHAR(500);
