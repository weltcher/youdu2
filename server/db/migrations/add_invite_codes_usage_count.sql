-- Add total_count and used_count columns to invite_codes table
-- Add total_count and used_count columns to invite_codes table

-- Add total_count column (default is 1)
ALTER TABLE invite_codes ADD COLUMN IF NOT EXISTS total_count INTEGER DEFAULT 1;

-- Add used_count column (default is 0)
ALTER TABLE invite_codes ADD COLUMN IF NOT EXISTS used_count INTEGER DEFAULT 0;

-- Update existing data: if status is used, set used_count to 1
UPDATE invite_codes SET used_count = 1 WHERE status = 'used' AND used_count = 0;

-- Add column comments
COMMENT ON COLUMN invite_codes.total_count IS 'Total number of times the invite code can be used';
COMMENT ON COLUMN invite_codes.used_count IS 'Number of times the invite code has been used';
