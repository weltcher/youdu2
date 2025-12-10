# Simple migration script
# Add deleted_by_users field to group_messages table

$DB_USER = "youdu_user"
$DB_NAME = "youdu_db"
$DB_HOST = "127.0.0.1"
$DB_PORT = "5432"
$MIGRATION_FILE = "db/migrations/add_deleted_by_users_to_group_messages.sql"

Write-Host "Applying migration..."
Write-Host "Database: $DB_NAME"
Write-Host "User: $DB_USER"
Write-Host ""

# Check if migration file exists
if (-not (Test-Path $MIGRATION_FILE)) {
    Write-Host "ERROR: Migration file not found: $MIGRATION_FILE"
    exit 1
}

# Prompt for password
$DB_PASSWORD = Read-Host "Enter database password" -AsSecureString
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($DB_PASSWORD)
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$env:PGPASSWORD = $PlainPassword

# Execute migration
Write-Host ""
Write-Host "Executing migration..."
psql -U $DB_USER -d $DB_NAME -h $DB_HOST -p $DB_PORT -f $MIGRATION_FILE

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Migration applied successfully!"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "1. Rebuild server: go build -o youdu_server.exe main.go"
    Write-Host "2. Run server: ./youdu_server.exe"
    Write-Host "3. Test group message delete function"
} else {
    Write-Host ""
    Write-Host "Migration failed!"
    exit 1
}

$env:PGPASSWORD = $null

