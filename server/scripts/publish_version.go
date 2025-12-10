// 版本发布脚本
// 用于录入版本信息并将升级包推送到OSS
// 使用方法:
//   Windows/Android: go run publish_version.go -platform windows -version 1.0.0 -file ./app.exe -notes "更新说明"
//   iOS (分发地址): go run publish_version.go -platform ios -version 1.0.0 -url "https://testflight.apple.com/xxx" -notes "更新说明"

package main

import (
	"bytes"
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/aliyun/aliyun-oss-go-sdk/oss"
	"github.com/joho/godotenv"
)

// Config 配置
type Config struct {
	ServerURL   string
	OSSEndpoint string
	OSSAccessKey string
	OSSSecretKey string
	OSSBucket   string
}

// AppVersion 版本信息
type AppVersion struct {
	ID           int     `json:"id"`
	Version      string  `json:"version"`
	Platform     string  `json:"platform"`
	PackageURL   *string `json:"package_url"`
	OSSObjectKey *string `json:"oss_object_key"`
	Status       string  `json:"status"`
}

// APIResponse API响应
type APIResponse struct {
	Code    int             `json:"code"`
	Message string          `json:"message"`
	Data    json.RawMessage `json:"data"`
}

var config Config

func main() {
	// 解析命令行参数
	platform := flag.String("platform", "", "平台: windows, android, ios")
	version := flag.String("version", "", "版本号，如 1.0.0")
	filePath := flag.String("file", "", "升级包文件路径 (Windows/Android)")
	distributionURL := flag.String("url", "", "分发地址 (iOS专用，如TestFlight链接)")
	notes := flag.String("notes", "", "升级说明")
	forceUpdate := flag.Bool("force", false, "是否强制更新")
	minVersion := flag.String("min-version", "", "最低支持版本")
	serverURL := flag.String("server", "http://localhost:8080", "服务器地址")
	publish := flag.Bool("publish", false, "创建后立即发布")
	envFile := flag.String("env", "../.env", ".env文件路径")

	flag.Parse()

	// 验证平台
	*platform = strings.ToLower(*platform)
	if *platform == "" || *version == "" {
		printUsage()
		os.Exit(1)
	}

	if *platform != "windows" && *platform != "android" && *platform != "ios" {
		fmt.Println("错误: 平台必须是 windows, android 或 ios")
		os.Exit(1)
	}

	// iOS平台使用分发地址，其他平台使用文件上传
	isIOSDistribution := *platform == "ios" && *distributionURL != ""

	if *platform == "ios" {
		// iOS: 必须提供分发地址或文件路径
		if *distributionURL == "" && *filePath == "" {
			fmt.Println("错误: iOS平台请提供 -url 分发地址（推荐）或 -file 文件路径")
			printUsage()
			os.Exit(1)
		}
		if *distributionURL != "" {
			isIOSDistribution = true
		}
	} else {
		// Windows/Android: 必须提供文件路径
		if *filePath == "" {
			fmt.Println("错误: Windows/Android平台必须提供 -file 文件路径")
			printUsage()
			os.Exit(1)
		}
	}

	// 如果不是iOS分发模式，检查文件是否存在
	if !isIOSDistribution {
		if _, err := os.Stat(*filePath); os.IsNotExist(err) {
			fmt.Printf("错误: 文件不存在: %s\n", *filePath)
			os.Exit(1)
		}
	}

	// 加载配置（iOS分发模式不需要OSS配置）
	if err := loadConfig(*envFile, *serverURL, isIOSDistribution); err != nil {
		fmt.Printf("错误: 加载配置失败: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("========================================")
	fmt.Println("       版本发布工具")
	fmt.Println("========================================")
	fmt.Printf("平台: %s\n", *platform)
	fmt.Printf("版本: %s\n", *version)
	if isIOSDistribution {
		fmt.Printf("模式: iOS分发地址\n")
		fmt.Printf("分发地址: %s\n", *distributionURL)
	} else {
		fmt.Printf("模式: 文件上传\n")
		fmt.Printf("文件: %s\n", *filePath)
	}
	fmt.Println("========================================")

	var ossKey, fileURL, fileHash string
	var fileSize int64
	var versionID int
	var err error

	if isIOSDistribution {
		// iOS分发模式：直接使用分发地址
		fmt.Println("\n[1/4] iOS分发模式，跳过OSS检查...")
		fmt.Println("\n[2/4] 使用分发地址...")
		fileURL = *distributionURL
		ossKey = "" // iOS分发模式没有OSS Key
		fileSize = 0
		fileHash = ""

		fmt.Println("\n[3/4] 创建版本记录...")
		versionID, err = createVersion(*platform, *version, fileURL, ossKey, *notes, *forceUpdate, *minVersion, fileSize, fileHash)
		if err != nil {
			fmt.Printf("错误: 创建版本记录失败: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("版本记录创建成功! ID: %d\n", versionID)
	} else {
		// 文件上传模式
		// 1. 检查并删除上一个版本的OSS文件
		fmt.Println("\n[1/5] 检查上一个版本...")
		if err := checkAndDeletePreviousVersion(*platform); err != nil {
			fmt.Printf("警告: %v\n", err)
		}

		// 2. 上传文件到OSS
		fmt.Println("\n[2/5] 上传文件到OSS...")
		ossKey, fileURL, fileSize, fileHash, err = uploadToOSS(*filePath, *platform, *version)
		if err != nil {
			fmt.Printf("错误: 上传文件失败: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("上传成功!\n")
		fmt.Printf("  OSS Key: %s\n", ossKey)
		fmt.Printf("  文件URL: %s\n", fileURL)
		fmt.Printf("  文件大小: %d bytes\n", fileSize)
		fmt.Printf("  文件MD5: %s\n", fileHash)

		// 3. 创建版本记录
		fmt.Println("\n[3/5] 创建版本记录...")
		versionID, err = createVersion(*platform, *version, fileURL, ossKey, *notes, *forceUpdate, *minVersion, fileSize, fileHash)
		if err != nil {
			fmt.Printf("错误: 创建版本记录失败: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("版本记录创建成功! ID: %d\n", versionID)
	}

	// 发布版本（如果指定）
	stepNum := "4/4"
	if !isIOSDistribution {
		stepNum = "4/5"
	}
	if *publish {
		fmt.Printf("\n[%s] 发布版本...\n", stepNum)
		if err := publishVersion(versionID); err != nil {
			fmt.Printf("错误: 发布版本失败: %v\n", err)
			os.Exit(1)
		}
		fmt.Println("版本发布成功!")
	} else {
		fmt.Printf("\n[%s] 跳过发布（使用 -publish 参数可自动发布）\n", stepNum)
	}

	if !isIOSDistribution {
		fmt.Println("\n[5/5] 完成!")
	}
	fmt.Println("========================================")
	fmt.Println("版本发布完成!")
	fmt.Printf("  版本ID: %d\n", versionID)
	if isIOSDistribution {
		fmt.Printf("  分发地址: %s\n", fileURL)
	} else {
		fmt.Printf("  下载地址: %s\n", fileURL)
	}
	if !*publish {
		fmt.Println("\n提示: 版本当前为草稿状态，请在管理后台发布或使用 -publish 参数")
	}
	fmt.Println("========================================")
}

func printUsage() {
	fmt.Println("用法:")
	fmt.Println("  Windows/Android: go run publish_version.go -platform <platform> -version <version> -file <file_path> [options]")
	fmt.Println("  iOS (分发地址): go run publish_version.go -platform ios -version <version> -url <distribution_url> [options]")
	fmt.Println("\n必需参数:")
	fmt.Println("  -platform    平台: windows, android, ios")
	fmt.Println("  -version     版本号，如 1.0.0")
	fmt.Println("  -file        升级包文件路径 (Windows/Android必需)")
	fmt.Println("  -url         分发地址 (iOS专用，如TestFlight/企业分发链接)")
	fmt.Println("\n可选参数:")
	fmt.Println("  -notes       升级说明")
	fmt.Println("  -force       是否强制更新 (默认: false)")
	fmt.Println("  -min-version 最低支持版本")
	fmt.Println("  -server      服务器地址 (默认: http://localhost:8080)")
	fmt.Println("  -publish     创建后立即发布 (默认: false)")
	fmt.Println("  -env         .env文件路径 (默认: ../.env)")
	fmt.Println("\n示例:")
	fmt.Println("  # Windows")
	fmt.Println("  go run publish_version.go -platform windows -version 1.0.0 -file ./app.exe -notes \"修复bug\" -publish")
	fmt.Println("  # Android")
	fmt.Println("  go run publish_version.go -platform android -version 1.0.0 -file ./app.apk -notes \"新功能\" -publish")
	fmt.Println("  # iOS (TestFlight)")
	fmt.Println("  go run publish_version.go -platform ios -version 1.0.0 -url \"https://testflight.apple.com/join/xxx\" -notes \"新版本\" -publish")
}


func loadConfig(envFile, serverURL string, skipOSSCheck bool) error {
	// 加载.env文件
	if err := godotenv.Load(envFile); err != nil {
		fmt.Printf("警告: 无法加载.env文件: %v，将使用环境变量\n", err)
	}

	config = Config{
		ServerURL:    serverURL,
		OSSEndpoint:  os.Getenv("S3_ENDPOINT"),
		OSSAccessKey: os.Getenv("S3_ACCESS_KEY"),
		OSSSecretKey: os.Getenv("S3_SECRET_KEY"),
		OSSBucket:    os.Getenv("S3_BUCKET"),
	}

	// iOS分发模式不需要OSS配置
	if !skipOSSCheck {
		if config.OSSEndpoint == "" || config.OSSAccessKey == "" || config.OSSSecretKey == "" || config.OSSBucket == "" {
			return fmt.Errorf("OSS配置不完整，请检查环境变量或.env文件")
		}
	}

	return nil
}

func checkAndDeletePreviousVersion(platform string) error {
	// 获取最新版本
	resp, err := http.Get(fmt.Sprintf("%s/api/version/latest?platform=%s", config.ServerURL, platform))
	if err != nil {
		return fmt.Errorf("请求失败: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == 404 {
		fmt.Println("没有找到上一个版本，跳过删除")
		return nil
	}

	if resp.StatusCode != 200 {
		return fmt.Errorf("获取版本信息失败，状态码: %d", resp.StatusCode)
	}

	var apiResp APIResponse
	if err := json.NewDecoder(resp.Body).Decode(&apiResp); err != nil {
		return fmt.Errorf("解析响应失败: %v", err)
	}

	var prevVersion AppVersion
	if err := json.Unmarshal(apiResp.Data, &prevVersion); err != nil {
		return fmt.Errorf("解析版本数据失败: %v", err)
	}

	if prevVersion.OSSObjectKey != nil && *prevVersion.OSSObjectKey != "" {
		fmt.Printf("找到上一个版本: %s, OSS Key: %s\n", prevVersion.Version, *prevVersion.OSSObjectKey)
		fmt.Println("删除上一个版本的OSS文件...")

		if err := deleteOSSFile(*prevVersion.OSSObjectKey); err != nil {
			return fmt.Errorf("删除OSS文件失败: %v", err)
		}
		fmt.Println("上一个版本的OSS文件已删除")
	} else {
		fmt.Println("上一个版本没有OSS文件")
	}

	return nil
}

func uploadToOSS(filePath, platform, version string) (ossKey, fileURL string, fileSize int64, fileHash string, err error) {
	// 创建OSS客户端
	client, err := oss.New(config.OSSEndpoint, config.OSSAccessKey, config.OSSSecretKey)
	if err != nil {
		return "", "", 0, "", fmt.Errorf("创建OSS客户端失败: %v", err)
	}

	bucket, err := client.Bucket(config.OSSBucket)
	if err != nil {
		return "", "", 0, "", fmt.Errorf("获取Bucket失败: %v", err)
	}

	// 读取文件
	file, err := os.Open(filePath)
	if err != nil {
		return "", "", 0, "", fmt.Errorf("打开文件失败: %v", err)
	}
	defer file.Close()

	// 获取文件信息
	fileInfo, err := file.Stat()
	if err != nil {
		return "", "", 0, "", fmt.Errorf("获取文件信息失败: %v", err)
	}
	fileSize = fileInfo.Size()

	// 计算MD5
	hash := md5.New()
	if _, err := io.Copy(hash, file); err != nil {
		return "", "", 0, "", fmt.Errorf("计算MD5失败: %v", err)
	}
	fileHash = hex.EncodeToString(hash.Sum(nil))

	// 重置文件指针
	file.Seek(0, 0)

	// 生成OSS Key
	ext := filepath.Ext(filePath)
	timestamp := time.Now().Format("20060102150405")
	ossKey = fmt.Sprintf("releases/%s/%s_%s%s", platform, version, timestamp, ext)

	// 上传文件
	fmt.Printf("正在上传文件 (%d bytes)...\n", fileSize)
	if err := bucket.PutObject(ossKey, file); err != nil {
		return "", "", 0, "", fmt.Errorf("上传文件失败: %v", err)
	}

	// 生成文件URL
	endpointHost := strings.TrimPrefix(config.OSSEndpoint, "https://")
	endpointHost = strings.TrimPrefix(endpointHost, "http://")
	fileURL = fmt.Sprintf("https://%s.%s/%s", config.OSSBucket, endpointHost, ossKey)

	return ossKey, fileURL, fileSize, fileHash, nil
}

func deleteOSSFile(objectKey string) error {
	client, err := oss.New(config.OSSEndpoint, config.OSSAccessKey, config.OSSSecretKey)
	if err != nil {
		return fmt.Errorf("创建OSS客户端失败: %v", err)
	}

	bucket, err := client.Bucket(config.OSSBucket)
	if err != nil {
		return fmt.Errorf("获取Bucket失败: %v", err)
	}

	return bucket.DeleteObject(objectKey)
}

func createVersion(platform, version, packageURL, ossKey, notes string, forceUpdate bool, minVersion string, fileSize int64, fileHash string) (int, error) {
	// 根据是否有ossKey判断分发类型
	distributionType := "oss"
	if ossKey == "" {
		distributionType = "url" // iOS分发地址模式
	}

	reqBody := map[string]interface{}{
		"platform":          platform,
		"version":           version,
		"distribution_type": distributionType,
		"package_url":       packageURL,
		"oss_object_key":    ossKey,
		"release_notes":     notes,
		"is_force_update":   forceUpdate,
		"file_size":         fileSize,
		"file_hash":         fileHash,
	}

	if minVersion != "" {
		reqBody["min_supported_version"] = minVersion
	}

	jsonData, err := json.Marshal(reqBody)
	if err != nil {
		return 0, fmt.Errorf("序列化请求失败: %v", err)
	}

	resp, err := http.Post(
		fmt.Sprintf("%s/api/app-versions", config.ServerURL),
		"application/json",
		bytes.NewBuffer(jsonData),
	)
	if err != nil {
		return 0, fmt.Errorf("请求失败: %v", err)
	}
	defer resp.Body.Close()

	var apiResp APIResponse
	if err := json.NewDecoder(resp.Body).Decode(&apiResp); err != nil {
		return 0, fmt.Errorf("解析响应失败: %v", err)
	}

	if apiResp.Code != 0 {
		return 0, fmt.Errorf("创建失败: %s", apiResp.Message)
	}

	var createdVersion AppVersion
	if err := json.Unmarshal(apiResp.Data, &createdVersion); err != nil {
		return 0, fmt.Errorf("解析版本数据失败: %v", err)
	}

	return createdVersion.ID, nil
}

func publishVersion(versionID int) error {
	req, err := http.NewRequest("POST", fmt.Sprintf("%s/api/app-versions/%d/publish", config.ServerURL, versionID), nil)
	if err != nil {
		return fmt.Errorf("创建请求失败: %v", err)
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("请求失败: %v", err)
	}
	defer resp.Body.Close()

	var apiResp APIResponse
	if err := json.NewDecoder(resp.Body).Decode(&apiResp); err != nil {
		return fmt.Errorf("解析响应失败: %v", err)
	}

	if apiResp.Code != 0 {
		return fmt.Errorf("发布失败: %s", apiResp.Message)
	}

	return nil
}
