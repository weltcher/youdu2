@echo off
REM 生成随机密钥工具

echo ========================================
echo 随机密钥生成工具
echo ========================================
echo.
echo 请选择密钥类型：
echo 1. JWT Secret (Base64, 32字符)
echo 2. 数据库密码 (字母数字+特殊字符, 16字符)
echo 3. 自定义
echo.

set /p CHOICE=请输入选项 (1-3): 

if "%CHOICE%"=="1" (
    echo.
    echo 生成 JWT Secret...
    go run generate_secret.go -type=base64 -length=32
) else if "%CHOICE%"=="2" (
    echo.
    echo 生成数据库密码...
    go run generate_secret.go -type=alphanumeric -length=16
) else if "%CHOICE%"=="3" (
    echo.
    set /p LENGTH=请输入密钥长度: 
    set /p TYPE=请输入类型 (base64/hex/alphanumeric): 
    echo.
    go run generate_secret.go -type=%TYPE% -length=%LENGTH%
) else (
    echo 无效选项！
)

echo.
pause









