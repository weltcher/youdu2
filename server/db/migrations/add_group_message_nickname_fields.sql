-- Add sender_nickname and sender_full_name fields to group_messages table
-- Migration date: 2025-12-03
-- Description: Add sender_nickname and sender_full_name fields to better support group nickname display

-- Add sender_nickname field
ALTER TABLE group_messages ADD COLUMN IF NOT EXISTS sender_nickname VARCHAR(100);

-- Add sender_full_name field
ALTER TABLE group_messages ADD COLUMN IF NOT EXISTS sender_full_name VARCHAR(100);

-- Add comments
COMMENT ON COLUMN group_messages.sender_nickname IS 'Sender group nickname (from group_members.nickname)';
COMMENT ON COLUMN group_messages.sender_full_name IS 'Sender full name (from users.full_name)';
