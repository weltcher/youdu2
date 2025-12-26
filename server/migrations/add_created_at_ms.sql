-- Add created_at_ms field (millisecond timestamp for precise sorting)
-- Execution time: 2024-12-26
-- Description: Add millisecond timestamp field to messages and group_messages tables to solve inaccurate conversation list sorting issue

-- 1. Add created_at_ms field to messages table
ALTER TABLE messages ADD COLUMN IF NOT EXISTS created_at_ms BIGINT;

-- 2. Add created_at_ms field to group_messages table
ALTER TABLE group_messages ADD COLUMN IF NOT EXISTS created_at_ms BIGINT;

-- 3. Migrate existing data: convert created_at to millisecond timestamp
-- Private chat messages
UPDATE messages 
SET created_at_ms = EXTRACT(EPOCH FROM created_at) * 1000 
WHERE created_at_ms IS NULL AND created_at IS NOT NULL;

-- Group chat messages
UPDATE group_messages 
SET created_at_ms = EXTRACT(EPOCH FROM created_at) * 1000 
WHERE created_at_ms IS NULL AND created_at IS NOT NULL;

-- 4. Create indexes to improve sorting performance
CREATE INDEX IF NOT EXISTS idx_messages_created_at_ms ON messages(created_at_ms DESC);
CREATE INDEX IF NOT EXISTS idx_group_messages_created_at_ms ON group_messages(created_at_ms DESC);

-- 5. Create triggers: automatically populate created_at_ms when inserting new messages
-- Private chat messages trigger
CREATE OR REPLACE FUNCTION set_messages_created_at_ms()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.created_at_ms IS NULL THEN
        NEW.created_at_ms := EXTRACT(EPOCH FROM COALESCE(NEW.created_at, NOW())) * 1000;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_messages_created_at_ms ON messages;
CREATE TRIGGER trigger_set_messages_created_at_ms
    BEFORE INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION set_messages_created_at_ms();

-- Group chat messages trigger
CREATE OR REPLACE FUNCTION set_group_messages_created_at_ms()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.created_at_ms IS NULL THEN
        NEW.created_at_ms := EXTRACT(EPOCH FROM COALESCE(NEW.created_at, NOW())) * 1000;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_set_group_messages_created_at_ms ON group_messages;
CREATE TRIGGER trigger_set_group_messages_created_at_ms
    BEFORE INSERT ON group_messages
    FOR EACH ROW
    EXECUTE FUNCTION set_group_messages_created_at_ms();

-- Verify migration results
SELECT 'messages' as table_name, COUNT(*) as total, COUNT(created_at_ms) as with_ms FROM messages
UNION ALL
SELECT 'group_messages' as table_name, COUNT(*) as total, COUNT(created_at_ms) as with_ms FROM group_messages;
