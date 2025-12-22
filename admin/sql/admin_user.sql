-- 创建 admin_user 表
CREATE TABLE IF NOT EXISTS admin_user (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  last_login_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 插入初始管理员账号
-- 密码 pao990820 使用 bcrypt 加密 (cost=10)，加盐: 前缀 F3w^t4 + 后缀 w9Ae712
INSERT INTO admin_user (username, password, created_at)
VALUES (
  'sanpao888',
  '$2a$10$/4HqIjuKXG3v/eFK56cutevzOMhPxpd1VEJjGjYDMx8ouK7ir7n1m',
  CURRENT_TIMESTAMP
) ON CONFLICT (username) DO NOTHING;
