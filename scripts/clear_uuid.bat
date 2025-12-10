@echo off
REM ============================================
REM Clear UUID and Application Data Script
REM ============================================
REM 
REM Purpose: Clear locally stored UUID and database to test UUID push on first installation
REM
REM Usage:
REM   1. Close the application
REM   2. Run this script as Administrator: clear_uuid.bat
REM   3. Ensure the server is running
REM   4. Restart the application
REM   5. Check logs for UUID push records
REM
REM ============================================

echo.
echo ============================================
echo    Clear UUID and Application Data
echo ============================================
echo.

REM Check for administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARN] Not running as Administrator
    echo [WARN] Recommended to run this script as Administrator
    echo.
    echo Right-click this file and select "Run as administrator"
    echo.
    timeout /t 3 >nul
)

REM Step 1: Delete application data directories
echo Step 1/3: Delete Application Data Directories
echo --------------------------------------------

set DB_PATH1=%LOCALAPPDATA%\ydapp
set DB_PATH2=%USERPROFILE%\Documents\youdu_db
set DELETED_COUNT=0

if exist "%DB_PATH1%" (
    echo    [INFO] Attempting to delete: %DB_PATH1%
    
    REM First attempt: normal delete
    rd /s /q "%DB_PATH1%" 2>nul
    
    REM Check if still exists
    if exist "%DB_PATH1%" (
        echo    [WARN] Normal delete failed, trying force delete...
        
        REM Second attempt: remove read-only attributes and force delete
        attrib -r -s -h "%DB_PATH1%\*.*" /s /d >nul 2>&1
        rd /s /q "%DB_PATH1%" 2>nul
        
        REM Final check
        if exist "%DB_PATH1%" (
            echo    [ERROR] Failed to delete: %DB_PATH1%
            echo    [ERROR] Please close all applications and try again
            echo    [ERROR] Or manually delete this directory
        ) else (
            echo    [OK] Deleted: %DB_PATH1%
            set /a DELETED_COUNT+=1
        )
    ) else (
        echo    [OK] Deleted: %DB_PATH1%
        set /a DELETED_COUNT+=1
    )
) else (
    echo    [INFO] Directory not found: %DB_PATH1%
)

if exist "%DB_PATH2%" (
    echo    [INFO] Attempting to delete: %DB_PATH2%
    
    REM First attempt: normal delete
    rd /s /q "%DB_PATH2%" 2>nul
    
    REM Check if still exists
    if exist "%DB_PATH2%" (
        echo    [WARN] Normal delete failed, trying force delete...
        
        REM Second attempt: remove read-only attributes and force delete
        attrib -r -s -h "%DB_PATH2%\*.*" /s /d >nul 2>&1
        rd /s /q "%DB_PATH2%" 2>nul
        
        REM Final check
        if exist "%DB_PATH2%" (
            echo    [ERROR] Failed to delete: %DB_PATH2%
            echo    [ERROR] Please close all applications and try again
            echo    [ERROR] Or manually delete this directory
        ) else (
            echo    [OK] Deleted: %DB_PATH2%
            set /a DELETED_COUNT+=1
        )
    ) else (
        echo    [OK] Deleted: %DB_PATH2%
        set /a DELETED_COUNT+=1
    )
) else (
    echo    [INFO] Directory not found: %DB_PATH2%
)

echo.

REM Step 2: Clear UUID from Windows Credential Manager
echo Step 2/3: Clear UUID from Windows Credential Manager
echo --------------------------------------------

set CRED_COUNT=0
for /f "tokens=*" %%a in ('cmdkey /list 2^>nul ^| findstr /i "flutter_secure_storage"') do (
    set LINE=%%a
    setlocal enabledelayedexpansion
    echo !LINE! | findstr /r "Target.*:" >nul
    if !errorlevel! equ 0 (
        for /f "tokens=2 delims=:" %%b in ("!LINE!") do (
            set TARGET=%%b
            set TARGET=!TARGET:~1!
            cmdkey /delete:!TARGET! >nul 2>&1
            if !errorlevel! equ 0 (
                echo    [OK] Deleted credential: !TARGET!
                set /a CRED_COUNT+=1
            ) else (
                echo    [ERROR] Failed to delete credential: !TARGET!
            )
        )
    )
    endlocal
)

if %CRED_COUNT% equ 0 (
    echo    [INFO] No flutter_secure_storage credentials found
)

echo.

REM Step 3: Verify cleanup results
echo Step 3/3: Verify Cleanup Results
echo --------------------------------------------

set ALL_CLEARED=1

if exist "%DB_PATH1%" (
    echo    [ERROR] Directory still exists: %DB_PATH1%
    set ALL_CLEARED=0
) else (
    echo    [OK] Directory cleared: %DB_PATH1%
)

if exist "%DB_PATH2%" (
    echo    [ERROR] Directory still exists: %DB_PATH2%
    set ALL_CLEARED=0
) else (
    echo    [OK] Directory cleared: %DB_PATH2%
)

echo.
echo ============================================

if %ALL_CLEARED% equ 1 (
    echo    [SUCCESS] Cleanup completed!
) else (
    echo    [WARN] Partial cleanup failed, please manually delete remaining files
)

echo ============================================
echo.

REM Next steps
echo Next Steps:
echo.
echo    1. Ensure the server is running
echo        cd server
echo        go run .\main.go
echo.
echo    2. Restart the application (will trigger UUID push)
echo        flutter run -d windows --debug
echo.
echo    3. Check logs to confirm UUID push success
echo        Client logs: logs\youdu_XX_YYYY-MM-DD.log
echo        Search keywords: 'old version upgrade detected' or 'device info push success'
echo.
echo        Server logs: server\logs\youdu-server_YYYY-MM-DD.log
echo        Search keywords: '[device registration]' or 'registration success'
echo.
echo    4. Verify database records
echo        psql -U postgres -h 127.0.0.1 -p 5432 -d youdu_db
echo        SELECT * FROM device_registrations;
echo.
echo ============================================
echo.

pause
