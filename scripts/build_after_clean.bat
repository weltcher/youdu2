@echo off
chcp 65001 >nul
echo ========================================
echo Flutter Build Script After Clean
echo ========================================
echo.

:: Set project path
set PROJECT_PATH=%~dp0
cd /d "%PROJECT_PATH%"

echo 📁 Current project path: %PROJECT_PATH%
echo.

:: Set OpenSSL 3.0.17 environment variables
echo 🔧 Setting OpenSSL 3.0.17 environment variables...
set OPENSSL_ROOT_DIR=C:\tools\openssl\openssl-3.0.17
set OPENSSL_INCLUDE_DIR=C:\tools\openssl\openssl-3.0.17\include
set OPENSSL_CRYPTO_LIBRARY=C:\tools\openssl\openssl-3.0.17\libcrypto.lib
set OPENSSL_SSL_LIBRARY=C:\tools\openssl\openssl-3.0.17\libssl.lib

echo ✅ OpenSSL environment variables set successfully
echo    OPENSSL_ROOT_DIR=%OPENSSL_ROOT_DIR%
echo    OPENSSL_INCLUDE_DIR=%OPENSSL_INCLUDE_DIR%
echo.

:: Check if OpenSSL path exists
if not exist "%OPENSSL_ROOT_DIR%" (
    echo ❌ Error: OpenSSL path does not exist: %OPENSSL_ROOT_DIR%
    echo Please check if OpenSSL 3.0.17 is properly installed
    pause
    exit /b 1
)

:: Execute Flutter Clean
echo 🧹 Executing Flutter Clean...
flutter clean
if %ERRORLEVEL% neq 0 (
    echo ❌ Flutter Clean failed
    pause
    exit /b 1
)
echo ✅ Flutter Clean completed
echo.

:: Get Flutter package dependencies
echo 📦 Getting Flutter package dependencies...
flutter pub get
if %ERRORLEVEL% neq 0 (
    echo ❌ Flutter pub get failed
    pause
    exit /b 1
)
echo ✅ Flutter package dependencies retrieved successfully
echo.

:: Build Windows application (Debug mode)
echo 🔨 Building Windows application (Debug mode)...
echo This may take a few minutes, please be patient...
echo.
flutter build windows --debug
if %ERRORLEVEL% neq 0 (
    echo ❌ Flutter build failed
    pause
    exit /b 1
)
echo ✅ Flutter Windows application build completed
echo.

:: Check generated key files
echo 🔍 Checking generated key files...
set BUILD_DIR=%PROJECT_PATH%build\windows\x64\runner\Debug

if exist "%BUILD_DIR%\youdu.exe" (
    echo ✅ Main executable: youdu.exe
) else (
    echo ❌ Main executable not found: youdu.exe
)

if exist "%BUILD_DIR%\sqlite3.dll" (
    echo ✅ SQLCipher library: sqlite3.dll
) else (
    echo ❌ SQLCipher library not found: sqlite3.dll
)

if exist "%BUILD_DIR%\sqlcipher_flutter_libs_plugin.dll" (
    echo ✅ SQLCipher plugin: sqlcipher_flutter_libs_plugin.dll
) else (
    echo ❌ SQLCipher plugin not found: sqlcipher_flutter_libs_plugin.dll
)

echo.
echo 🎉 Build completed!
echo 📂 Output directory: %BUILD_DIR%
echo.
echo 💡 Tip: You can now run the following command to start the application:
echo    flutter run -d windows --debug
echo.

pause
