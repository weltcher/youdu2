package main

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
)

func main() {
	encryptCmd := flag.Bool("encrypt", false, "加密 .env 文件")
	decryptCmd := flag.Bool("decrypt", false, "解密 .env.encrypted 文件")
	password := flag.String("password", "", "加密/解密密码")
	flag.Parse()

	if *password == "" {
		fmt.logger.debugln("错误：必须提供密码 -password")
		flag.Usage()
		os.Exit(1)
	}

	// 获取 server 目录路径
	serverDir := filepath.Join("..")
	envFile := filepath.Join(serverDir, ".env")
	encryptedFile := filepath.Join(serverDir, ".env.encrypted")

	if *encryptCmd {
		// 加密 .env 文件
		if err := encryptFile(envFile, encryptedFile, *password); err != nil {
			fmt.logger.debugf("加密失败: %v\n", err)
			os.Exit(1)
		}
		fmt.logger.debugln("✅ .env 文件已加密为 .env.encrypted")
		fmt.logger.debugln("⚠️  可以安全地提交 .env.encrypted 到版本控制")
		fmt.logger.debugln("⚠️  请妥善保管加密密码！")
	} else if *decryptCmd {
		// 解密 .env.encrypted 文件
		if err := decryptFile(encryptedFile, envFile, *password); err != nil {
			fmt.logger.debugf("解密失败: %v\n", err)
			os.Exit(1)
		}
		fmt.logger.debugln("✅ .env.encrypted 已解密为 .env")
	} else {
		fmt.logger.debugln("请指定操作: -encrypt 或 -decrypt")
		flag.Usage()
		os.Exit(1)
	}
}

// encryptFile 加密文件
func encryptFile(inputFile, outputFile, password string) error {
	// 读取原文件
	plaintext, err := os.ReadFile(inputFile)
	if err != nil {
		return fmt.Errorf("读取文件失败: %w", err)
	}

	// 使用密码生成密钥
	key := sha256.Sum256([]byte(password))

	// 创建 AES 加密块
	block, err := aes.NewCipher(key[:])
	if err != nil {
		return fmt.Errorf("创建加密块失败: %w", err)
	}

	// 创建 GCM 模式
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return fmt.Errorf("创建 GCM 失败: %w", err)
	}

	// 生成随机 nonce
	nonce := make([]byte, gcm.NonceSize())
	if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
		return fmt.Errorf("生成 nonce 失败: %w", err)
	}

	// 加密数据
	ciphertext := gcm.Seal(nonce, nonce, plaintext, nil)

	// 编码为 base64 并写入文件
	encoded := base64.StdEncoding.EncodeToString(ciphertext)
	if err := os.WriteFile(outputFile, []byte(encoded), 0644); err != nil {
		return fmt.Errorf("写入加密文件失败: %w", err)
	}

	return nil
}

// decryptFile 解密文件
func decryptFile(inputFile, outputFile, password string) error {
	// 读取加密文件
	encoded, err := os.ReadFile(inputFile)
	if err != nil {
		return fmt.Errorf("读取加密文件失败: %w", err)
	}

	// 解码 base64
	ciphertext, err := base64.StdEncoding.DecodeString(string(encoded))
	if err != nil {
		return fmt.Errorf("解码 base64 失败: %w", err)
	}

	// 使用密码生成密钥
	key := sha256.Sum256([]byte(password))

	// 创建 AES 解密块
	block, err := aes.NewCipher(key[:])
	if err != nil {
		return fmt.Errorf("创建解密块失败: %w", err)
	}

	// 创建 GCM 模式
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return fmt.Errorf("创建 GCM 失败: %w", err)
	}

	// 提取 nonce
	nonceSize := gcm.NonceSize()
	if len(ciphertext) < nonceSize {
		return fmt.Errorf("密文太短")
	}
	nonce, ciphertext := ciphertext[:nonceSize], ciphertext[nonceSize:]

	// 解密数据
	plaintext, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return fmt.Errorf("解密失败（密码可能错误）: %w", err)
	}

	// 写入解密后的文件
	if err := os.WriteFile(outputFile, plaintext, 0600); err != nil {
		return fmt.Errorf("写入解密文件失败: %w", err)
	}

	return nil
}
