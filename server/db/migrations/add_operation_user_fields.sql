-- Add operation user fields to user_relations table
-- Used to record who performed the block and delete operations

-- Add blocked_by_user_id field
ALTER TABLE user_relations 
ADD COLUMN IF NOT EXISTS blocked_by_user_id INTEGER;

-- Add deleted_by_user_id field
ALTER TABLE user_relations 
ADD COLUMN IF NOT EXISTS deleted_by_user_id INTEGER;

-- Add column comments
COMMENT ON COLUMN user_relations.blocked_by_user_id IS 'User ID who performed the block operation';
COMMENT ON COLUMN user_relations.deleted_by_user_id IS 'User ID who performed the delete operation';

-- Set default values for existing data (if is_blocked=true, set blocked_by_user_id to user_id)
UPDATE user_relations 
SET blocked_by_user_id = user_id 
WHERE is_blocked = true AND blocked_by_user_id IS NULL;

-- Set default values for existing data (if is_deleted=true, set deleted_by_user_id to user_id)
UPDATE user_relations 
SET deleted_by_user_id = user_id 
WHERE is_deleted = true AND deleted_by_user_id IS NULL;
