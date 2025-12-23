-- 添加最近登录时间字段
-- Add last_login_at column to users table

ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP DEFAULT NULL;

COMMENT ON COLUMN users.last_login_at IS 'User last login timestamp';
