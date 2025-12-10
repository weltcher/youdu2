-- Add voice_duration field to messages table
ALTER TABLE messages ADD COLUMN IF NOT EXISTS voice_duration INTEGER;

-- Add voice_duration field to group_messages table
ALTER TABLE group_messages ADD COLUMN IF NOT EXISTS voice_duration INTEGER;

-- Add comments
COMMENT ON COLUMN messages.voice_duration IS 'Voice message duration (seconds)';
COMMENT ON COLUMN group_messages.voice_duration IS 'Voice message duration (seconds)';
