@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo        版本发布工具
echo ========================================
echo.

:: 检查参数
if "%1"=="" (
    echo 用法: publish_version.bat ^<platform^> ^<version^> ^<file_path^> [options]
    echo.
    echo 示例:
    echo   publish_version.bat windows 1.0.0 .\app.exe
    echo   publish_version.bat android 1.0.0 .\app.apk -notes "修复bug"
    echo   publish_version.bat ios 1.0.0 .\app.ipa -publish
    echo.
    echo 参数:
    echo   platform    平台: windows, android, ios
    echo   version     版本号，如 1.0.0
    echo   file_path   升级包文件路径
    echo.
    echo 可选参数:
    echo   -notes "说明"      升级说明
    echo   -force             强制更新
    echo   -min-version "版本" 最低支持版本
    echo   -publish           创建后立即发布
    echo   -server "地址"     服务器地址 (默认: http://localhost:8080)
    exit /b 1
)

set PLATFORM=%1
set VERSION=%2
set FILE_PATH=%3

:: 移除前三个参数，剩余的作为额外参数
shift
shift
shift

set EXTRA_ARGS=
:parse_args
if "%1"=="" goto run
set EXTRA_ARGS=%EXTRA_ARGS% %1
shift
goto parse_args

:run
echo 平台: %PLATFORM%
echo 版本: %VERSION%
echo 文件: %FILE_PATH%
echo.

:: 运行Go脚本
go run publish_version.go -platform %PLATFORM% -version %VERSION% -file %FILE_PATH% %EXTRA_ARGS%

if %ERRORLEVEL% neq 0 (
    echo.
    echo 发布失败!
    exit /b 1
)

echo.
echo 发布完成!
