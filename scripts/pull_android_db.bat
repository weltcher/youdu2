@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM Android Database Export Script (Batch Version)
REM ============================================================
REM Purpose: Export application database from Android device to project root
REM 
REM Prerequisites:
REM 1. Android device connected with USB debugging enabled
REM 2. Device has Root access
REM 3. ADB tools installed
REM
REM Usage:
REM .\scripts\pull_android_db.bat
REM ============================================================

echo.
echo ============================================
echo    Android Database Export Tool
echo ============================================
echo.

REM 1. Check if ADB is available
echo Step 1/4: Check ADB Environment
echo --------------------------------------------
adb version >nul 2>&1
if errorlevel 1 (
    echo    [ERROR] ADB not installed or not in PATH
    echo.
    echo Please install Android SDK Platform-Tools and add to PATH
    exit /b 1
)
echo    [OK] ADB is ready
echo.

REM 2. Check device connection
echo Step 2/4: Check Device Connection
echo --------------------------------------------
adb devices | findstr "device$" >nul
if errorlevel 1 (
    echo    [ERROR] No Android device detected
    echo.
    echo Please ensure:
    echo    1. Device is connected via USB
    echo    2. USB debugging is enabled
    echo    3. USB debugging authorization is granted
    echo.
    echo You can check device with command:
    echo    adb devices
    exit /b 1
)
echo    [OK] Device connected
echo.

REM 3. Copy database from device to sdcard
echo Step 3/4: Copy Database to SD Card
echo --------------------------------------------
echo    Database path: /data/data/com.example.youdu/databases/youdu_messages.db

REM Execute copy command (requires root)
adb shell "su -c 'cp /data/data/com.example.youdu/databases/youdu_messages.db /sdcard/'" >nul 2>&1

REM Check if copy succeeded
adb shell "ls /sdcard/youdu_messages.db" 2>&1 | findstr "No such file" >nul
if not errorlevel 1 (
    echo    [ERROR] Database copy failed
    echo.
    echo Possible reasons:
    echo    1. Device does not have Root access
    echo    2. App not installed or incorrect package name
    echo    3. Database file does not exist
    echo.
    echo Please manually execute following commands to troubleshoot:
    echo    adb shell
    echo    su
    echo    ls /data/data/com.example.youdu/databases/
    exit /b 1
)

echo    [OK] Database copied to /sdcard/youdu_messages.db
echo.

REM 4. Pull database from device to project root
echo Step 4/4: Download Database to Project Directory
echo --------------------------------------------

REM Get project root directory (parent of script directory)
cd /d "%~dp0.."
set TARGET_PATH=%CD%\youdu_messages.db

echo    Target path: %TARGET_PATH%

REM Backup if target file already exists
if exist "%TARGET_PATH%" (
    set TIMESTAMP=%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%
    set TIMESTAMP=!TIMESTAMP: =0!
    set BACKUP_PATH=%CD%\youdu_messages.db.backup_!TIMESTAMP!
    echo    [INFO] Found existing database file, backing up to:
    echo           !BACKUP_PATH!
    move /y "%TARGET_PATH%" "!BACKUP_PATH!" >nul
)

REM Pull database
adb pull /sdcard/youdu_messages.db . >nul 2>&1
if errorlevel 1 (
    echo    [ERROR] Database download failed
    exit /b 1
)

REM Verify file was successfully downloaded
if exist "%TARGET_PATH%" (
    for %%A in ("%TARGET_PATH%") do set FILE_SIZE=%%~zA
    set /a FILE_SIZE_KB=!FILE_SIZE! / 1024
    echo    [OK] Database downloaded
    echo    File size: !FILE_SIZE_KB! KB
) else (
    echo    [ERROR] Database file not found
    exit /b 1
)

echo.

REM 5. Clean up temporary file on device
echo Cleaning up temporary files...
adb shell rm /sdcard/youdu_messages.db >nul 2>&1
echo    [OK] Temporary files cleaned
echo.

REM Complete
echo ============================================
echo    [SUCCESS] Database export completed!
echo ============================================
echo.
echo Database location: %TARGET_PATH%
echo File size: !FILE_SIZE_KB! KB
echo.
echo Next steps - run test scripts:
echo    1. Get UUID:
echo       .\scripts\get_db_password.ps1
echo.
echo    2. Test Android database:
echo       dart run test_db_encryption2.dart ^<UUID^> --android
echo.
echo    3. Test iOS database:
echo       dart run test_db_encryption2.dart ^<UUID^> --ios
echo.

pause
