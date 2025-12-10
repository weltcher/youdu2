package utils

import (
	"regexp"
)

// IsValidPhoneNumber 验证手机号格式（中国大陆）
// 规则：1开头，第二位是3-9，共11位数字
func IsValidPhoneNumber(phone string) bool {
	phoneRegex := regexp.MustCompile(`^1[3-9]\d{9}$`)
	return phoneRegex.MatchString(phone)
}

// IsValidEmail 验证邮箱格式
func IsValidEmail(email string) bool {
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`)
	return emailRegex.MatchString(email)
}

// IsValidVerifyCode 验证验证码格式
// 规则：6位纯数字
func IsValidVerifyCode(code string) bool {
	codeRegex := regexp.MustCompile(`^\d{6}$`)
	return codeRegex.MatchString(code)
}
