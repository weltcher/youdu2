@echo off
chcp 65001 >nul

:: 快速编译脚本 - 适用于日常开发
echo 🚀 Flutter 快速编译脚本
echo ========================

:: 设置 OpenSSL 环境变量
set OPENSSL_ROOT_DIR=C:\tools\openssl\openssl-3.0.17
set OPENSSL_INCLUDE_DIR=C:\tools\openssl\openssl-3.0.17\include
set OPENSSL_CRYPTO_LIBRARY=C:\tools\openssl\openssl-3.0.17\libcrypto.lib
set OPENSSL_SSL_LIBRARY=C:\tools\openssl\openssl-3.0.17\libssl.lib

echo ✅ OpenSSL 环境变量已设置
echo.

:: 编译并运行
echo 🔨 编译并运行应用...
flutter run -d windows --debug

pause
