-- 创建邀请码使用记录表
CREATE TABLE IF NOT EXISTS invite_code_usages (
    id SERIAL PRIMARY KEY,
    invite_code_id INTEGER NOT NULL REFERENCES invite_codes(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    used_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(invite_code_id, user_id)
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_invite_code_usages_invite_code_id ON invite_code_usages(invite_code_id);
CREATE INDEX IF NOT EXISTS idx_invite_code_usages_user_id ON invite_code_usages(user_id);

-- 迁移现有数据：从 invite_codes 表的 used_by_user_id 迁移到新表
INSERT INTO invite_code_usages (invite_code_id, user_id, used_at)
SELECT id, used_by_user_id, used_at
FROM invite_codes
WHERE used_by_user_id IS NOT NULL
ON CONFLICT (invite_code_id, user_id) DO NOTHING;

-- 也从 users 表的 invited_by_code 迁移数据
INSERT INTO invite_code_usages (invite_code_id, user_id, used_at)
SELECT ic.id, u.id, u.created_at
FROM users u
JOIN invite_codes ic ON u.invited_by_code = ic.code
WHERE u.invited_by_code IS NOT NULL
ON CONFLICT (invite_code_id, user_id) DO NOTHING;

-- 可选：删除 invite_codes 表中的冗余字段（建议先测试后再执行）
-- ALTER TABLE invite_codes DROP COLUMN IF EXISTS used_by_user_id;
-- ALTER TABLE invite_codes DROP COLUMN IF EXISTS used_by_username;
-- ALTER TABLE invite_codes DROP COLUMN IF EXISTS used_by_fullname;
-- ALTER TABLE invite_codes DROP COLUMN IF EXISTS used_at;
