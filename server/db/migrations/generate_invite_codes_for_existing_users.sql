-- 为没有邀请码的老用户生成邀请码
-- 使用 PostgreSQL 的随机字符串生成功能

-- 创建一个函数来生成随机邀请码
CREATE OR REPLACE FUNCTION generate_random_invite_code()
RETURNS VARCHAR(6) AS $$
DECLARE
    chars TEXT := '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    result VARCHAR(6) := '';
    i INTEGER;
BEGIN
    FOR i IN 1..6 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 为所有没有邀请码的用户生成唯一邀请码
DO $$
DECLARE
    user_record RECORD;
    new_code VARCHAR(6);
    code_exists BOOLEAN;
BEGIN
    FOR user_record IN SELECT id FROM users WHERE invite_code IS NULL OR invite_code = '' LOOP
        LOOP
            -- 生成新的邀请码
            new_code := generate_random_invite_code();
            
            -- 检查是否已存在
            SELECT EXISTS(SELECT 1 FROM users WHERE invite_code = new_code) INTO code_exists;
            
            -- 如果不存在，则使用这个邀请码
            EXIT WHEN NOT code_exists;
        END LOOP;
        
        -- 更新用户的邀请码
        UPDATE users SET invite_code = new_code WHERE id = user_record.id;
        RAISE NOTICE 'Generated invite code % for user %', new_code, user_record.id;
    END LOOP;
END $$;

-- 清理临时函数
DROP FUNCTION IF EXISTS generate_random_invite_code();

-- 验证结果
SELECT id, username, invite_code FROM users WHERE invite_code IS NOT NULL ORDER BY id;
