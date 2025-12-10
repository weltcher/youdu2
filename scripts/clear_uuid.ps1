# ============================================
# Clear UUID and Application Data Script
# ============================================
# 
# Purpose: Clear locally stored UUID and database to test UUID push on first installation
#
# Usage:
#   1. Close the application
#   2. Run this script: .\clear_uuid.ps1
#   3. Ensure the server is running
#   4. Restart the application
#   5. Check logs for UUID push records
#
# ============================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "   Clear UUID and Application Data" -ForegroundColor Yellow  
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check admin privileges (optional)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[WARN] Recommended to run this script as Administrator" -ForegroundColor Yellow
    Write-Host ""
}

# Step 1: Delete application data directories
Write-Host "Step 1/3: Delete Application Data Directories" -ForegroundColor Green
Write-Host "--------------------------------------------" -ForegroundColor Gray

$dbPath1 = "$env:LOCALAPPDATA\ydapp"
$dbPath2 = "$env:USERPROFILE\Documents\youdu_db"
$deletedCount = 0

if (Test-Path $dbPath1) {
    try {
        Remove-Item -Path $dbPath1 -Recurse -Force -ErrorAction Stop
        Write-Host "   [OK] Deleted: $dbPath1" -ForegroundColor Yellow
        $deletedCount++
    } catch {
        Write-Host "   [ERROR] Failed to delete: $dbPath1" -ForegroundColor Red
        Write-Host "      Error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   [INFO] Directory not found: $dbPath1" -ForegroundColor Gray
}

if (Test-Path $dbPath2) {
    try {
        Remove-Item -Path $dbPath2 -Recurse -Force -ErrorAction Stop
        Write-Host "   [OK] Deleted: $dbPath2" -ForegroundColor Yellow
        $deletedCount++
    } catch {
        Write-Host "   [ERROR] Failed to delete: $dbPath2" -ForegroundColor Red
        Write-Host "      Error: $_" -ForegroundColor Red
    }
} else {
    Write-Host "   [INFO] Directory not found: $dbPath2" -ForegroundColor Gray
}

Write-Host ""

# Step 2: Clear UUID from Windows Credential Manager
Write-Host "Step 2/3: Clear UUID from Windows Credential Manager" -ForegroundColor Green
Write-Host "--------------------------------------------" -ForegroundColor Gray

try {
    $creds = cmdkey /list 2>$null | Select-String "flutter_secure_storage"
    if ($creds) {
        $credCount = 0
        $creds | ForEach-Object {
            $line = $_.ToString()
            # Match Chinese/English "Target"
            if ($line -match "Target:\s*(.+)" -or $line -match "目标:\s*(.+)") {
                $target = $matches[1].Trim()
                try {
                    cmdkey /delete:$target 2>$null | Out-Null
                    Write-Host "   [OK] Deleted credential: $target" -ForegroundColor Yellow
                    $credCount++
                } catch {
                    Write-Host "   [ERROR] Failed to delete credential: $target" -ForegroundColor Red
                }
            }
        }
        if ($credCount -eq 0) {
            Write-Host "   [INFO] No flutter_secure_storage credentials found to delete" -ForegroundColor Gray
        }
    } else {
        Write-Host "   [INFO] No flutter_secure_storage credentials found" -ForegroundColor Gray
    }
} catch {
    Write-Host "   [ERROR] Error clearing credentials: $_" -ForegroundColor Red
}

Write-Host ""

# Step 3: Verify cleanup results
Write-Host "Step 3/3: Verify Cleanup Results" -ForegroundColor Green
Write-Host "--------------------------------------------" -ForegroundColor Gray

$allCleared = $true

if (Test-Path $dbPath1) {
    Write-Host "   [ERROR] Directory still exists: $dbPath1" -ForegroundColor Red
    $allCleared = $false
} else {
    Write-Host "   [OK] Directory cleared: $dbPath1" -ForegroundColor Green
}

if (Test-Path $dbPath2) {
    Write-Host "   [ERROR] Directory still exists: $dbPath2" -ForegroundColor Red
    $allCleared = $false
} else {
    Write-Host "   [OK] Directory cleared: $dbPath2" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan

if ($allCleared) {
    Write-Host "   [SUCCESS] Cleanup completed!" -ForegroundColor Green
} else {
    Write-Host "   [WARN] Partial cleanup failed, please manually delete remaining files" -ForegroundColor Yellow
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Next steps
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   1. Ensure the server is running" -ForegroundColor White
Write-Host "       cd server" -ForegroundColor Gray
Write-Host "       go run .\main.go" -ForegroundColor Gray
Write-Host ""
Write-Host "   2. Restart the application (will trigger UUID push)" -ForegroundColor White
Write-Host "       flutter run -d windows --debug" -ForegroundColor Gray
Write-Host ""
Write-Host "   3. Check logs to confirm UUID push success" -ForegroundColor White
Write-Host "       Client logs: logs\youdu_XX_YYYY-MM-DD.log" -ForegroundColor Gray
Write-Host "       Search keywords: 'old version upgrade detected' or 'device info push success'" -ForegroundColor Gray
Write-Host ""
Write-Host "       Server logs: server\logs\youdu-server_YYYY-MM-DD.log" -ForegroundColor Gray
Write-Host "       Search keywords: '[device registration]' or 'registration success'" -ForegroundColor Gray
Write-Host ""
Write-Host "   4. Verify database records" -ForegroundColor White
Write-Host "       psql -U postgres -h 127.0.0.1 -p 5432 -d youdu_db" -ForegroundColor Gray
Write-Host "       SELECT * FROM device_registrations;" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
