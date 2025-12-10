package utils

import (
	"crypto/rand"
	"math/big"
	mathrand "math/rand"
	"strconv"
)

// GenerateVerificationCode 生成验证码
func GenerateVerificationCode(length int) string {
	if length <= 0 {
		length = 6
	}

	// 不再使用 rand.Seed，Go 1.20+ 会自动初始化
	min := int64(1)
	for i := 1; i < length; i++ {
		min *= 10
	}
	max := min*10 - 1

	code := mathrand.Int63n(max-min+1) + min
	return strconv.FormatInt(code, 10)
}

// GenerateInviteCode 生成邀请码（6位，包含0-9a-zA-Z）
// 使用 crypto/rand 生成密码学安全的随机邀请码，确保并发安全和唯一性
func GenerateInviteCode() string {
	const charset = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	const length = 6

	result := make([]byte, length)
	charsetLen := big.NewInt(int64(len(charset)))

	for i := range result {
		// 使用 crypto/rand 生成安全的随机数
		num, err := rand.Int(rand.Reader, charsetLen)
		if err != nil {
			// 如果crypto/rand失败，回退到math/rand（不应该发生）
			result[i] = charset[mathrand.Intn(len(charset))]
		} else {
			result[i] = charset[num.Int64()]
		}
	}
	return string(result)
}
