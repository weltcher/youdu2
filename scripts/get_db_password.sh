#!/bin/bash

# ============================================
# 数据库密码获取工具 (Bash)
# ============================================
# 
# 使用方法：
#   1. 通过UUID生成密码：
#      ./get_db_password.sh <uuid>
#
#   2. 读取已存储的密码：
#      ./get_db_password.sh --read
#      或: ./get_db_password.sh -r
#
#   3. 显示帮助：
#      ./get_db_password.sh --help
#      或: ./get_db_password.sh -h
#
# 示例：
#   ./get_db_password.sh 123e4567-e89b-12d3-a456-426614174000
#
# ============================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    echo ""
    echo -e "${CYAN}=================================${NC}"
    echo -e "${CYAN}数据库密码获取工具${NC}"
    echo -e "${CYAN}=================================${NC}"
    echo ""
    echo -e "${YELLOW}使用方法：${NC}"
    echo "  1. 通过UUID生成密码："
    echo "     ./get_db_password.sh <uuid>"
    echo ""
    echo "  2. 读取已存储的密码："
    echo "     ./get_db_password.sh --read"
    echo "     或: ./get_db_password.sh -r"
    echo ""
    echo "  3. 显示帮助："
    echo "     ./get_db_password.sh --help"
    echo "     或: ./get_db_password.sh -h"
    echo ""
    echo -e "${YELLOW}示例：${NC}"
    echo "  ./get_db_password.sh 123e4567-e89b-12d3-a456-426614174000"
    echo ""
}

# 验证UUID格式
validate_uuid() {
    local uuid=$1
    local uuid_pattern="^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
    
    if [[ $uuid =~ $uuid_pattern ]]; then
        return 0
    else
        return 1
    fi
}

# 通过UUID生成数据库密码
generate_password() {
    local uuid=$1
    
    echo ""
    echo -e "${CYAN}=================================${NC}"
    echo -e "${CYAN}数据库密码生成${NC}"
    echo -e "${CYAN}=================================${NC}"
    echo ""
    echo -e "${GREEN}📝 输入的UUID:${NC} $uuid"
    echo ""
    
    # 验证UUID格式
    if ! validate_uuid "$uuid"; then
        echo -e "${YELLOW}⚠️  警告：UUID格式可能不正确${NC}"
        echo -e "${YELLOW}标准UUID格式: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx${NC}"
        echo ""
    fi
    
    # 拼接固定字符串
    local combined="${uuid}S4F9hjn"
    echo -e "${GREEN}🔗 拼接字符串:${NC} $combined"
    
    # MD5加密
    local md5_hash
    if command -v md5sum &> /dev/null; then
        md5_hash=$(echo -n "$combined" | md5sum | awk '{print $1}')
    elif command -v md5 &> /dev/null; then
        # macOS使用md5命令
        md5_hash=$(echo -n "$combined" | md5)
    else
        echo -e "${RED}❌ 错误：未找到md5sum或md5命令${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}🔐 MD5哈希值:${NC}  $md5_hash"
    
    # 取前6位和后6位拼成12位密钥
    local password="${md5_hash:0:6}${md5_hash:26:6}"
    
    echo ""
    echo -e "${GREEN}✅ 生成的数据库密码:${NC} ${YELLOW}$password${NC}"
    echo -e "${GRAY}   (前6位: ${WHITE}${md5_hash:0:6}${GRAY} + 后6位: ${WHITE}${md5_hash:26:6}${GRAY})${NC}"
    echo ""
    echo -e "${CYAN}=================================${NC}"
    echo ""
}

# 读取存储的密码
read_stored_password() {
    echo ""
    echo -e "${CYAN}=================================${NC}"
    echo -e "${CYAN}读取存储的数据库密码${NC}"
    echo -e "${CYAN}=================================${NC}"
    echo ""
    
    local os_type=$(uname)
    
    case "$os_type" in
        "Darwin")
            # macOS - 使用Keychain
            echo -e "${GREEN}📂 正在查询macOS Keychain...${NC}"
            echo ""
            
            if command -v security &> /dev/null; then
                # 尝试读取flutter_secure_storage的密钥
                local password=$(security find-generic-password -s "flutter_secure_storage" -a "ydkey" -w 2>/dev/null)
                
                if [ $? -eq 0 ] && [ -n "$password" ]; then
                    echo -e "${GREEN}✅ 找到存储的密码:${NC} ${YELLOW}$password${NC}"
                    echo ""
                else
                    echo -e "${YELLOW}⚠️  未找到存储的密码${NC}"
                    echo ""
                    echo -e "${GRAY}可能原因：${NC}"
                    echo "  1. 应用尚未运行过，密码未生成"
                    echo "  2. 密码已被清除"
                    echo "  3. 使用了不同的用户账户"
                    echo ""
                    echo -e "${YELLOW}💡 手动查看方法：${NC}"
                    echo "   1. 打开 '钥匙串访问' 应用"
                    echo "   2. 搜索: flutter_secure_storage"
                    echo "   3. 查看 'ydkey' 项的密码字段"
                    echo ""
                fi
            else
                echo -e "${RED}❌ 未找到security命令${NC}"
                echo ""
            fi
            ;;
            
        "Linux")
            # Linux - 使用libsecret
            echo -e "${GREEN}📂 正在查询Linux Keyring...${NC}"
            echo ""
            
            if command -v secret-tool &> /dev/null; then
                # 尝试读取flutter_secure_storage的密钥
                local password=$(secret-tool lookup key ydkey 2>/dev/null)
                
                if [ $? -eq 0 ] && [ -n "$password" ]; then
                    echo -e "${GREEN}✅ 找到存储的密码:${NC} ${YELLOW}$password${NC}"
                    echo ""
                else
                    echo -e "${YELLOW}⚠️  未找到存储的密码${NC}"
                    echo ""
                    echo -e "${GRAY}可能原因：${NC}"
                    echo "  1. 应用尚未运行过，密码未生成"
                    echo "  2. 密码已被清除"
                    echo "  3. 使用了不同的用户账户"
                    echo ""
                    echo -e "${YELLOW}💡 手动查看方法：${NC}"
                    echo "   使用命令: secret-tool lookup key ydkey"
                    echo ""
                fi
            else
                echo -e "${RED}❌ 未找到secret-tool命令${NC}"
                echo -e "${YELLOW}💡 请安装: sudo apt-get install libsecret-tools${NC}"
                echo ""
            fi
            ;;
            
        *)
            echo -e "${RED}❌ 不支持的操作系统: $os_type${NC}"
            echo ""
            ;;
    esac
    
    echo -e "${CYAN}=================================${NC}"
    echo ""
}

# 主逻辑
case "${1}" in
    --help|-h)
        show_help
        exit 0
        ;;
    --read|-r)
        read_stored_password
        exit 0
        ;;
    "")
        echo ""
        echo -e "${RED}❌ 错误：请提供UUID参数${NC}"
        show_help
        exit 1
        ;;
    *)
        generate_password "$1"
        exit 0
        ;;
esac
