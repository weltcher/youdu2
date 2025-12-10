#!/bin/bash

# Set UTF-8 encoding
export LC_ALL=C.UTF-8

echo "============================================"
echo "  Database Migration for Call Fields"
echo "============================================"
echo

# Set PostgreSQL password
export PGPASSWORD=""

echo "Step 1: Add call_type column"
psql -U postgres -h 127.0.0.1 -d youdu_db -c "ALTER TABLE group_messages ADD COLUMN IF NOT EXISTS call_type VARCHAR(20);"
if [ $? -eq 0 ]; then
    echo "[OK] call_type column added"
else
    echo "[ERROR] Failed to add call_type column"
    read -p "Press Enter to continue..."
    exit 1
fi

echo
echo "Step 2: Add channel_name column"
psql -U postgres -h 127.0.0.1 -d youdu_db -c "ALTER TABLE group_messages ADD COLUMN IF NOT EXISTS channel_name VARCHAR(255);"
if [ $? -eq 0 ]; then
    echo "[OK] channel_name column added"
else
    echo "[ERROR] Failed to add channel_name column"
    read -p "Press Enter to continue..."
    exit 1
fi

echo
echo "Step 3: Add column comments"
psql -U postgres -h 127.0.0.1 -d youdu_db -c "COMMENT ON COLUMN group_messages.call_type IS 'Call type (voice/video), only used for call_initiated type messages';"
psql -U postgres -h 127.0.0.1 -d youdu_db -c "COMMENT ON COLUMN group_messages.channel_name IS 'Agora channel name, used to join group calls, only used for call_initiated type messages';"
echo "[OK] Comments added"

echo
echo "Step 4: Create indexes"
psql -U postgres -h 127.0.0.1 -d youdu_db -c "CREATE INDEX IF NOT EXISTS idx_group_messages_call_type ON group_messages(call_type) WHERE call_type IS NOT NULL;"
psql -U postgres -h 127.0.0.1 -d youdu_db -c "CREATE INDEX IF NOT EXISTS idx_group_messages_channel_name ON group_messages(channel_name) WHERE channel_name IS NOT NULL;"
echo "[OK] Indexes created"

echo
echo "Step 5: Verify columns exist"
psql -U postgres -h 127.0.0.1 -d youdu_db -c "SELECT column_name, data_type, character_maximum_length FROM information_schema.columns WHERE table_name = 'group_messages' AND column_name IN ('call_type', 'channel_name') ORDER BY column_name;"

echo
echo "============================================"
echo "  [SUCCESS] Migration completed!"
echo "============================================"
echo
echo "Next Step: Restart the server"
echo "  cd server"
echo "  go run ./main.go"
echo
read -p "Press Enter to continue..."
