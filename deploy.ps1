$sourceDir = "C:\Users\WIN10\source\flutter\chat\youdu\build\windows\x64\runner\Debug"
$targetDir = "C:\Users\WIN10\Documents\shared\System Volume Information\Debug"

# Step 1: Delete old files in the target directory
Write-Host "[Step 1/2] Deleting old files in the target directory..." -ForegroundColor Yellow

# Delete data directory
$targetDataDir = Join-Path $targetDir "data"
if (Test-Path $targetDataDir) {
    Write-Host "  - Deleting directory: $targetDataDir" -ForegroundColor Gray
    Remove-Item -Path $targetDataDir -Recurse -Force
    Write-Host "  ✓ data directory deleted" -ForegroundColor Green
} else {
    Write-Host "  - data directory does not exist, skipping" -ForegroundColor Gray
}

# Delete youdu.exe
$targetExe = Join-Path $targetDir "youdu.exe"
if (Test-Path $targetExe) {
    Write-Host "  - Deleting file: $targetExe" -ForegroundColor Gray
    Remove-Item -Path $targetExe -Force
    Write-Host "  ✓ youdu.exe deleted" -ForegroundColor Green
} else {
    Write-Host "  - youdu.exe does not exist, skipping" -ForegroundColor Gray
}

# Delete youdu.pdb
$targetPdb = Join-Path $targetDir "youdu.pdb"
if (Test-Path $targetPdb) {
    Write-Host "  - Deleting file: $targetPdb" -ForegroundColor Gray
    Remove-Item -Path $targetPdb -Force
    Write-Host "  ✓ youdu.pdb deleted" -ForegroundColor Green
} else {
    Write-Host "  - youdu.pdb does not exist, skipping" -ForegroundColor Gray
}

Write-Host ""

# Step 2: Copy new files to target directory
Write-Host "[Step 2/2] Copying new files to target directory..." -ForegroundColor Yellow

# Ensure target directory exists
if (-not (Test-Path $targetDir)) {
    Write-Host "  - Creating target directory: $targetDir" -ForegroundColor Gray
    New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
}

# Copy data directory
$sourceDataDir = Join-Path $sourceDir "data"
if (Test-Path $sourceDataDir) {
    Write-Host "  - Copying directory: data" -ForegroundColor Gray
    Copy-Item -Path $sourceDataDir -Destination $targetDir -Recurse -Force
    Write-Host "  ✓ data directory copied" -ForegroundColor Green
} else {
    Write-Host "  ✗ Source data directory does not exist: $sourceDataDir" -ForegroundColor Red
}

# Copy youdu.exe
$sourceExe = Join-Path $sourceDir "youdu.exe"
if (Test-Path $sourceExe) {
    Write-Host "  - Copying file: youdu.exe" -ForegroundColor Gray
    Copy-Item -Path $sourceExe -Destination $targetDir -Force
    Write-Host "  ✓ youdu.exe copied" -ForegroundColor Green
} else {
    Write-Host "  ✗ Source file does not exist: $sourceExe" -ForegroundColor Red
}

# Copy youdu.pdb
$sourcePdb = Join-Path $sourceDir "youdu.pdb"
if (Test-Path $sourcePdb) {
    Write-Host "  - Copying file: youdu.pdb" -ForegroundColor Gray
    Copy-Item -Path $sourcePdb -Destination $targetDir -Force
    Write-Host "  ✓ youdu.pdb copied" -ForegroundColor Green
} else {
    Write-Host "  ✗ Source file does not exist: $sourcePdb" -ForegroundColor Red
}

Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Deployment completed!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Source directory: $sourceDir" -ForegroundColor Gray
Write-Host "Target directory: $targetDir" -ForegroundColor Gray
