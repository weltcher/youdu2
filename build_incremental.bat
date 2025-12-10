@echo off
REM Incremental build script - only compiles changed files
echo ====================================
echo Incremental Build Mode
echo ====================================

REM Do not clean cache, use incremental build
echo [1/3] Checking dependencies...
call flutter pub get --no-precompile

echo.
echo [2/3] Incremental build (only compiling changed files)...
call flutter build windows --debug --no-tree-shake-icons --no-pub

echo.
echo ====================================
echo Incremental build complete!
echo Output: build\windows\x64\runner\Debug\youdu.exe
echo ====================================

call flutter run -d windows --debug