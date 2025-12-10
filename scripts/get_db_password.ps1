# ============================================
# Database Password Retrieval Tool (PowerShell)
# ============================================
# 
# Usage:
#   1. Generate password from UUID:
#      .\get_db_password.ps1 <uuid>
#      or: .\get_db_password.ps1 -uuid <uuid>
#
#   2. Read stored password:
#      .\get_db_password.ps1 -read
#      or: .\get_db_password.ps1 -r
#
#   3. Show help:
#      .\get_db_password.ps1 -help
#      or: .\get_db_password.ps1 -h
#
# Example:
#   .\get_db_password.ps1 123e4567-e89b-12d3-a456-426614174000
#
# ============================================

param(
    [Parameter(Position=0)]
    [string]$uuid,
    
    [Alias("r")]
    [switch]$read,
    
    [Alias("h")]
    [switch]$help
)

# Show help information
function Show-Help {
    Write-Host ""
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host "Database Password Retrieval Tool" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  1. Generate password from UUID:"
    Write-Host "     .\get_db_password.ps1 <uuid>"
    Write-Host "     or: .\get_db_password.ps1 -uuid <uuid>"
    Write-Host ""
    Write-Host "  2. Read stored password:"
    Write-Host "     .\get_db_password.ps1 -read"
    Write-Host "     or: .\get_db_password.ps1 -r"
    Write-Host ""
    Write-Host "  3. Show help:"
    Write-Host "     .\get_db_password.ps1 -help"
    Write-Host "     or: .\get_db_password.ps1 -h"
    Write-Host ""
    Write-Host "Example:" -ForegroundColor Yellow
    Write-Host "  .\get_db_password.ps1 123e4567-e89b-12d3-a456-426614174000"
    Write-Host ""
}

# MD5 hash function
function Get-MD5Hash {
    param([string]$text)
    
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $hashBytes = $md5.ComputeHash($bytes)
    
    $hashString = [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
    return $hashString
}

# Validate UUID format
function Test-UUIDFormat {
    param([string]$uuid)
    
    $uuidPattern = "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
    return $uuid -match $uuidPattern
}

# Generate database password from UUID
function Get-PasswordFromUUID {
    param([string]$uuid)
    
    Write-Host ""
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host "Database Password Generation" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[INPUT] UUID: " -NoNewline -ForegroundColor Green
    Write-Host $uuid
    Write-Host ""
    
    # Validate UUID format
    if (-not (Test-UUIDFormat $uuid)) {
        Write-Host "[WARN] UUID format may be incorrect" -ForegroundColor Yellow
        Write-Host "Standard UUID format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -ForegroundColor Yellow
        Write-Host ""
    }
    
    # Concatenate with salt string
    $salt = "Uau7W7KuW6qKcd2bBkGP"
    $combined = $uuid + $salt
    Write-Host "[CONCAT] Combined string (UUID + Salt): " -NoNewline -ForegroundColor Green
    Write-Host $combined
    
    # MD5 encryption
    $md5Hash = Get-MD5Hash $combined
    Write-Host "[MD5] Hash value:  " -NoNewline -ForegroundColor Green
    Write-Host $md5Hash
    
    $password = $md5Hash.Substring(0, 8) + $md5Hash.Substring(24, 8)
    
    Write-Host ""
    Write-Host "[SUCCESS] Generated database password: " -NoNewline -ForegroundColor Green
    Write-Host $password -ForegroundColor Yellow
    Write-Host "   (First 8: " -NoNewline -ForegroundColor Gray
    Write-Host $md5Hash.Substring(0, 8) -NoNewline -ForegroundColor White
    Write-Host " + Last 8: " -NoNewline -ForegroundColor Gray
    Write-Host $md5Hash.Substring(24, 8) -NoNewline -ForegroundColor White
    Write-Host ")" -ForegroundColor Gray
    Write-Host ""
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""
}

# Read password stored in Windows Credential Manager
function Get-StoredPassword {
    Write-Host ""
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host "Read Stored Database Password" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[INFO] Querying Windows Credential Manager..." -ForegroundColor Green
    Write-Host ""
    
    try {
        # Try to find flutter_secure_storage credentials
        $credentials = cmdkey /list | Select-String "flutter_secure_storage"
        
        if ($credentials) {
            Write-Host "[OK] Found Flutter secure storage credentials:" -ForegroundColor Green
            Write-Host $credentials
            Write-Host ""
            Write-Host "[TIP] How to view:" -ForegroundColor Yellow
            Write-Host "   1. Open Control Panel > Credential Manager > Windows Credentials"
            Write-Host "   2. Search for 'flutter_secure_storage'"
            Write-Host "   3. View the 'ydkey' value in the password field"
            Write-Host ""
        } else {
            Write-Host "[WARN] No stored password found" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Possible reasons:" -ForegroundColor Gray
            Write-Host "  1. Application has not been run yet, password not generated"
            Write-Host "  2. Password has been cleared"
            Write-Host "  3. Using a different user account"
            Write-Host ""
            Write-Host "[TIP] Manual check method:" -ForegroundColor Yellow
            Write-Host "   1. Press Win + R, type: control keymgr.dll"
            Write-Host "   2. Search in Windows Credentials: flutter_secure_storage"
            Write-Host "   3. View the password field"
            Write-Host ""
        }
    } catch {
        Write-Host "[ERROR] Failed to read credentials: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "[TIP] Manual check method:" -ForegroundColor Yellow
        Write-Host "   Open Control Panel > Credential Manager > Windows Credentials"
        Write-Host "   Search: flutter_secure_storage"
        Write-Host ""
    }
    
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host ""
}

# Main logic
if ($help) {
    Show-Help
    exit 0
}

if ($read) {
    Get-StoredPassword
    exit 0
}

if ([string]::IsNullOrWhiteSpace($uuid)) {
    Write-Host ""
    Write-Host "[ERROR] Please provide UUID parameter" -ForegroundColor Red
    Show-Help
    exit 1
}

Get-PasswordFromUUID $uuid

# 询问是否运行数据库测试
Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Run Database Encryption Test?" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Do you want to run the database encryption test with this UUID? (Y/N): " -NoNewline -ForegroundColor Yellow
$runTest = Read-Host

if ($runTest -eq 'Y' -or $runTest -eq 'y') {
    Write-Host ""
    Write-Host "🚀 Running database encryption test..." -ForegroundColor Green
    Write-Host ""
    
    $scriptPath = Join-Path $PSScriptRoot ".." "test_db_encryption2.dart"
    
    if (Test-Path $scriptPath) {
        dart run $scriptPath $uuid
    } else {
        Write-Host "❌ Test script not found: $scriptPath" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "💡 You can manually run the test with:" -ForegroundColor Cyan
    Write-Host "   dart run test_db_encryption2.dart $uuid" -ForegroundColor White
    Write-Host ""
}
