-- Add invite code fields to users table
-- Please backup database before executing this migration

-- 1. Add invite code columns
ALTER TABLE users ADD COLUMN IF NOT EXISTS invite_code VARCHAR(6) DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS invited_by_code VARCHAR(6) DEFAULT NULL;

-- 2. Add column comments
COMMENT ON COLUMN users.invite_code IS 'User''s own invite code (6 characters, 0-9a-zA-Z)';
COMMENT ON COLUMN users.invited_by_code IS 'Invite code used during registration';

-- 3. Create unique index to ensure invite codes are unique
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_invite_code ON users(invite_code) WHERE invite_code IS NOT NULL;

-- 4. Create index to improve query performance
CREATE INDEX IF NOT EXISTS idx_users_invited_by_code ON users(invited_by_code) WHERE invited_by_code IS NOT NULL;

-- 5. Generate invite codes for existing users (optional)
-- Note: This is not executed automatically, handle existing users manually after migration
-- UPDATE users SET invite_code = ... WHERE invite_code IS NULL;
