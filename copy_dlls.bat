@echo off
REM 自动复制 SQLCipher 相关 DLL

echo.
echo ========================================
echo   自动复制 SQLCipher DLL
echo ========================================
echo.

REM 检查构建模式参数
set BUILD_MODE=Debug
if not "%1"=="" set BUILD_MODE=%1

echo 构建模式: %BUILD_MODE%
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0windows\copy_sqlcipher_dlls.ps1" -BuildMode %BUILD_MODE%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ DLL 复制成功！
) else (
    echo.
    echo ❌ DLL 复制失败！
    pause
    exit /b 1
)

echo.
pause
