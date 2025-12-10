package main

import (
	"crypto/rand"
	"encoding/base64"
	"flag"
	"fmt"
	"math/big"
	"os"
)

func main() {
	length := flag.Int("length", 32, "密钥长度")
	typeFlag := flag.String("type", "base64", "密钥类型: base64, hex, alphanumeric")
	flag.Parse()

	var secret string
	var err error

	switch *typeFlag {
	case "base64":
		secret, err = generateBase64Secret(*length)
	case "hex":
		secret, err = generateHexSecret(*length)
	case "alphanumeric":
		secret, err = generateAlphanumericSecret(*length)
	default:
		fmt.logger.debugf("未知类型: %s\n", *typeFlag)
		fmt.logger.debugln("支持的类型: base64, hex, alphanumeric")
		os.Exit(1)
	}

	if err != nil {
		fmt.logger.debugf("生成密钥失败: %v\n", err)
		os.Exit(1)
	}

	fmt.logger.debugln("===================================")
	fmt.logger.debugf("生成的密钥（%s, %d字符）:\n", *typeFlag, len(secret))
	fmt.logger.debugln("===================================")
	fmt.logger.debugln(secret)
	fmt.logger.debugln("===================================")
	fmt.logger.debugln()
	fmt.logger.debugln("⚠️  请妥善保管此密钥！")
	fmt.logger.debugln("⚠️  不要将密钥提交到版本控制系统！")
}

// generateBase64Secret 生成 Base64 编码的随机密钥
func generateBase64Secret(length int) (string, error) {
	// Base64 编码后会比原始字节长，所以生成的字节数要少一些
	byteLength := (length * 3) / 4
	if byteLength < 1 {
		byteLength = 16
	}

	bytes := make([]byte, byteLength)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}

	secret := base64.URLEncoding.EncodeToString(bytes)
	// 截取到指定长度
	if len(secret) > length {
		secret = secret[:length]
	}

	return secret, nil
}

// generateHexSecret 生成十六进制密钥
func generateHexSecret(length int) (string, error) {
	const hexChars = "0123456789abcdef"
	return generateRandomString(length, hexChars)
}

// generateAlphanumericSecret 生成字母数字混合密钥
func generateAlphanumericSecret(length int) (string, error) {
	const chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
	return generateRandomString(length, chars)
}

// generateRandomString 生成随机字符串
func generateRandomString(length int, charset string) (string, error) {
	result := make([]byte, length)
	charsetLength := big.NewInt(int64(len(charset)))

	for i := range result {
		randomIndex, err := rand.Int(rand.Reader, charsetLength)
		if err != nil {
			return "", err
		}
		result[i] = charset[randomIndex.Int64()]
	}

	return string(result), nil
}
