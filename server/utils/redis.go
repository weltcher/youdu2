package utils

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

var RedisClient *redis.Client
var ctx = context.Background()

// InitRedis 初始化Redis连接
func InitRedis(host, port, password string, db int) error {
	RedisClient = redis.NewClient(&redis.Options{
		Addr:     fmt.Sprintf("%s:%s", host, port),
		Password: password,
		DB:       db,
	})

	// 测试连接
	_, err := RedisClient.Ping(ctx).Result()
	if err != nil {
		return fmt.Errorf("Redis连接失败: %v", err)
	}

	LogDebug("✅ Redis连接成功: %s:%s", host, port)
	return nil
}

// getLoginSMSKey 生成登录短信验证码的Redis key
// key格式: login-sms:{手机号}
func getLoginSMSKey(phone string) string {
	return fmt.Sprintf("login-sms:%s", phone)
}

// SetLoginSMSCode 设置登录短信验证码
// key格式: login-sms:{手机号}
// 有效期: 120秒
func SetLoginSMSCode(phone, code string) error {
	key := getLoginSMSKey(phone)
	err := RedisClient.Set(ctx, key, code, 120*time.Second).Err()
	if err != nil {
		return fmt.Errorf("设置验证码失败: %v", err)
	}
	LogDebug("✅ 验证码已保存到Redis: key=%s, code=%s, 有效期=120秒", key, code)
	return nil
}

// GetLoginSMSCode 获取登录短信验证码
func GetLoginSMSCode(phone string) (string, error) {
	key := getLoginSMSKey(phone)
	code, err := RedisClient.Get(ctx, key).Result()
	if err == redis.Nil {
		return "", fmt.Errorf("验证码不存在或已过期")
	}
	if err != nil {
		return "", fmt.Errorf("获取验证码失败: %v", err)
	}
	return code, nil
}

// DeleteLoginSMSCode 删除登录短信验证码
func DeleteLoginSMSCode(phone string) error {
	key := getLoginSMSKey(phone)
	return RedisClient.Del(ctx, key).Err()
}

// CheckLoginSMSCodeExists 检查验证码是否存在（未过期）
func CheckLoginSMSCodeExists(phone string) bool {
	key := getLoginSMSKey(phone)
	exists, err := RedisClient.Exists(ctx, key).Result()
	if err != nil {
		return false
	}
	return exists > 0
}
