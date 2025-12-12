#!/bin/bash
# 生成自签名SSL证书（用于开发测试）
# 生产环境请使用正式的CA签发证书

echo "正在生成自签名SSL证书..."

# 创建证书目录
mkdir -p certs

# 使用OpenSSL生成证书
openssl req -x509 -newkey rsa:4096 -keyout certs/server.key -out certs/server.crt -days 365 -nodes -subj "/C=CN/ST=Beijing/L=Beijing/O=YourCompany/OU=IT/CN=localhost"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 证书生成成功！"
    echo "📜 证书文件: certs/server.crt"
    echo "🔑 密钥文件: certs/server.key"
    echo ""
    echo "⚠️  注意：这是自签名证书，仅用于开发测试"
    echo "   生产环境请使用正式的CA签发证书（如Let's Encrypt）"
else
    echo ""
    echo "❌ 证书生成失败！"
    echo "请确保已安装OpenSSL"
fi
