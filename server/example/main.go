package main

import (
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/aliyun/aliyun-oss-go-sdk/oss"
	"github.com/joho/godotenv"
)

func main() {
	_ = godotenv.Load()

	endpoint := os.Getenv("S3_ENDPOINT") // 例如 oss-cn-hangzhou.aliyuncs.com 或 https://oss-cn-hangzhou.aliyuncs.com
	accessKey := os.Getenv("S3_ACCESS_KEY")
	secretKey := os.Getenv("S3_SECRET_KEY")
	bucketName := os.Getenv("S3_BUCKET")

	// 去掉 endpoint 的 https:// 前缀（OSS SDK 不需要）
	endpoint = strings.TrimPrefix(endpoint, "https://")
	endpoint = strings.TrimPrefix(endpoint, "http://")

	fmt.logger.debugln("--------------------------------")
	fmt.logger.debugln("endpoint:", endpoint)
	fmt.logger.debugln("accessKey:", accessKey)
	fmt.logger.debugln("secretKey:", secretKey)
	fmt.logger.debugln("bucketName:", bucketName)
	fmt.logger.debugln("--------------------------------")

	// 检查本地文件是否存在
	localFile := "uploads/test2.txt"
	if _, err := os.Stat(localFile); os.IsNotExist(err) {
		// 文件不存在，创建一个测试文件
		fmt.logger.debugf("⚠️  文件 %s 不存在，正在创建...\n", localFile)
		content := []byte("这是一个测试文件，用于测试阿里云OSS上传功能。\nThis is a test file for Aliyun OSS upload test.\n")
		if err := os.WriteFile(localFile, content, 0644); err != nil {
			log.Fatalf("创建测试文件失败: %v", err)
		}
		fmt.logger.debugln("✅ 测试文件创建成功")
	}

	client, err := oss.New(endpoint, accessKey, secretKey)
	if err != nil {
		log.Fatalf("创建OSS客户端失败: %v", err)
	}

	bucket, err := client.Bucket(bucketName)
	if err != nil {
		log.Fatalf("获取Bucket失败: %v", err)
	}

	// 上传本地文件
	err = bucket.PutObjectFromFile("test2.txt", "uploads/test2.txt")
	if err != nil {
		log.Fatalf("上传文件失败: %v", err)
	}

	fmt.logger.debugln("✅ 上传成功到 OSS:", endpoint)
}
