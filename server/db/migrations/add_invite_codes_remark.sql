-- Add remark column to invite_codes table
-- Add remark column to invite_codes table

-- Add remark column (if not exists)
ALTER TABLE invite_codes ADD COLUMN IF NOT EXISTS remark VARCHAR(500);

-- Add column comment
COMMENT ON COLUMN invite_codes.remark IS 'Invite code remark information';
