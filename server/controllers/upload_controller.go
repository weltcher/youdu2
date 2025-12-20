package controllers

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"youdu-server/utils"

	"github.com/aliyun/aliyun-oss-go-sdk/oss"
	"github.com/gin-gonic/gin"
	"github.com/spf13/viper"
)

// UploadController 上传控制器
type UploadController struct{}

// NewUploadController 创建上传控制器
func NewUploadController() *UploadController {
	return &UploadController{}
}

// UploadImage 上传图片到阿里云OSS（聊天图片）
func (ctrl *UploadController) UploadImage(c *gin.Context) {
	// 获取上传的文件
	file, err := c.FormFile("file")
	if err != nil {
		utils.BadRequest(c, "获取文件失败: "+err.Error())
		return
	}

	// 验证文件类型
	ext := strings.ToLower(filepath.Ext(file.Filename))
	allowedExts := map[string]bool{
		".jpg":  true,
		".jpeg": true,
		".png":  true,
		".gif":  true,
		".webp": true,
	}
	if !allowedExts[ext] {
		utils.BadRequest(c, "不支持的文件格式，仅支持 jpg, jpeg, png, gif, webp")
		return
	}

	// 验证文件大小（最大50MB）
	if file.Size > 50*1024*1024 {
		utils.BadRequest(c, "文件大小不能超过50MB")
		return
	}

	// 读取OSS配置（优先使用环境变量，然后使用viper配置文件）
	endpoint := os.Getenv("S3_ENDPOINT")
	if endpoint == "" {
		endpoint = viper.GetString("S3_ENDPOINT")
	}

	accessKey := os.Getenv("S3_ACCESS_KEY")
	if accessKey == "" {
		accessKey = viper.GetString("S3_ACCESS_KEY")
	}

	secretKey := os.Getenv("S3_SECRET_KEY")
	if secretKey == "" {
		secretKey = viper.GetString("S3_SECRET_KEY")
	}

	bucketName := os.Getenv("S3_BUCKET")
	if bucketName == "" {
		bucketName = viper.GetString("S3_BUCKET")
	}

	if endpoint == "" || accessKey == "" || secretKey == "" || bucketName == "" {
		utils.LogDebug("OSS配置缺失: endpoint=%s, accessKey=%s, secretKey=%s, bucket=%s",
			endpoint, accessKey, secretKey, bucketName)
		utils.InternalServerError(c, "OSS配置未设置")
		return
	}

	// 创建OSS客户端
	client, err := oss.New(endpoint, accessKey, secretKey)
	if err != nil {
		utils.LogDebug("创建OSS客户端失败: %v", err)
		utils.InternalServerError(c, "创建OSS客户端失败")
		return
	}

	// 获取Bucket
	bucket, err := client.Bucket(bucketName)
	if err != nil {
		utils.LogDebug("获取Bucket失败: %v", err)
		utils.InternalServerError(c, "获取Bucket失败")
		return
	}

	// 生成唯一的文件名
	// 所有通过此接口上传的图片都放在images目录（聊天图片）
	timestamp := time.Now().Unix()
	objectKey := fmt.Sprintf("images/%d_%s", timestamp, file.Filename)

	// 打开上传的文件
	src, err := file.Open()
	if err != nil {
		utils.LogDebug("打开文件失败: %v", err)
		utils.InternalServerError(c, "打开文件失败")
		return
	}
	defer src.Close()

	// 上传到OSS
	err = bucket.PutObject(objectKey, src)
	if err != nil {
		utils.LogDebug("上传文件到OSS失败: %v", err)
		utils.InternalServerError(c, "上传文件失败")
		return
	}

	// 构建文件URL
	// 优先使用CDN域名，如果没有配置则使用OSS原始域名
	cdnDomain := os.Getenv("S3_CDN_DOMAIN")
	if cdnDomain == "" {
		cdnDomain = viper.GetString("S3_CDN_DOMAIN")
	}
	var fileURL string
	if cdnDomain != "" {
		fileURL = fmt.Sprintf("https://%s/%s", cdnDomain, objectKey)
	} else {
		fileURL = fmt.Sprintf("https://%s.%s/%s", bucketName, strings.TrimPrefix(endpoint, "https://"), objectKey)
	}

	utils.SuccessWithMessage(c, "文件上传成功", gin.H{
		"url":       fileURL,
		"file_name": file.Filename,
		"size":      file.Size,
	})
}

// UploadFile 上传通用文件到阿里云OSS
func (ctrl *UploadController) UploadFile(c *gin.Context) {
	// 获取上传的文件
	file, err := c.FormFile("file")
	if err != nil {
		utils.BadRequest(c, "获取文件失败: "+err.Error())
		return
	}

	// 验证文件大小（最大200MB）
	if file.Size > 200*1024*1024 {
		utils.BadRequest(c, "文件大小不能超过200MB")
		return
	}

	// 读取OSS配置
	endpoint := os.Getenv("S3_ENDPOINT")
	if endpoint == "" {
		endpoint = viper.GetString("S3_ENDPOINT")
	}

	accessKey := os.Getenv("S3_ACCESS_KEY")
	if accessKey == "" {
		accessKey = viper.GetString("S3_ACCESS_KEY")
	}

	secretKey := os.Getenv("S3_SECRET_KEY")
	if secretKey == "" {
		secretKey = viper.GetString("S3_SECRET_KEY")
	}

	bucketName := os.Getenv("S3_BUCKET")
	if bucketName == "" {
		bucketName = viper.GetString("S3_BUCKET")
	}

	if endpoint == "" || accessKey == "" || secretKey == "" || bucketName == "" {
		utils.LogDebug("OSS配置缺失: endpoint=%s, accessKey=%s, secretKey=%s, bucket=%s",
			endpoint, accessKey, secretKey, bucketName)
		utils.InternalServerError(c, "OSS配置未设置")
		return
	}

	// 创建OSS客户端
	client, err := oss.New(endpoint, accessKey, secretKey)
	if err != nil {
		utils.LogDebug("创建OSS客户端失败: %v", err)
		utils.InternalServerError(c, "创建OSS客户端失败")
		return
	}

	// 获取Bucket
	bucket, err := client.Bucket(bucketName)
	if err != nil {
		utils.LogDebug("获取Bucket失败: %v", err)
		utils.InternalServerError(c, "获取Bucket失败")
		return
	}

	// 生成唯一的文件名
	timestamp := time.Now().Unix()
	objectKey := fmt.Sprintf("files/%d_%s", timestamp, file.Filename)

	// 打开上传的文件
	src, err := file.Open()
	if err != nil {
		utils.LogDebug("打开文件失败: %v", err)
		utils.InternalServerError(c, "打开文件失败")
		return
	}
	defer src.Close()

	// 上传到OSS
	err = bucket.PutObject(objectKey, src)
	if err != nil {
		utils.LogDebug("上传文件到OSS失败: %v", err)
		utils.InternalServerError(c, "上传文件失败")
		return
	}

	// 构建文件URL - 优先使用CDN域名
	cdnDomain := os.Getenv("S3_CDN_DOMAIN")
	if cdnDomain == "" {
		cdnDomain = viper.GetString("S3_CDN_DOMAIN")
	}
	var fileURL string
	if cdnDomain != "" {
		fileURL = fmt.Sprintf("https://%s/%s", cdnDomain, objectKey)
	} else {
		fileURL = fmt.Sprintf("https://%s.%s/%s", bucketName, strings.TrimPrefix(endpoint, "https://"), objectKey)
	}

	utils.SuccessWithMessage(c, "文件上传成功", gin.H{
		"url":       fileURL,
		"file_name": file.Filename,
		"size":      file.Size,
	})
}

// UploadAvatar 上传头像到阿里云OSS
func (ctrl *UploadController) UploadAvatar(c *gin.Context) {
	// 获取上传的文件
	file, err := c.FormFile("file")
	if err != nil {
		utils.BadRequest(c, "获取文件失败: "+err.Error())
		return
	}

	// 验证文件类型
	ext := strings.ToLower(filepath.Ext(file.Filename))
	allowedExts := map[string]bool{
		".jpg":  true,
		".jpeg": true,
		".png":  true,
		".gif":  true,
		".webp": true,
	}
	if !allowedExts[ext] {
		utils.BadRequest(c, "不支持的文件格式，仅支持 jpg, jpeg, png, gif, webp")
		return
	}

	// 验证文件大小（最大50MB）
	if file.Size > 50*1024*1024 {
		utils.BadRequest(c, "文件大小不能超过50MB")
		return
	}

	// 读取OSS配置
	endpoint := os.Getenv("S3_ENDPOINT")
	if endpoint == "" {
		endpoint = viper.GetString("S3_ENDPOINT")
	}

	accessKey := os.Getenv("S3_ACCESS_KEY")
	if accessKey == "" {
		accessKey = viper.GetString("S3_ACCESS_KEY")
	}

	secretKey := os.Getenv("S3_SECRET_KEY")
	if secretKey == "" {
		secretKey = viper.GetString("S3_SECRET_KEY")
	}

	bucketName := os.Getenv("S3_BUCKET")
	if bucketName == "" {
		bucketName = viper.GetString("S3_BUCKET")
	}

	if endpoint == "" || accessKey == "" || secretKey == "" || bucketName == "" {
		utils.LogDebug("OSS配置缺失: endpoint=%s, accessKey=%s, secretKey=%s, bucket=%s",
			endpoint, accessKey, secretKey, bucketName)
		utils.InternalServerError(c, "OSS配置未设置")
		return
	}

	// 创建OSS客户端
	client, err := oss.New(endpoint, accessKey, secretKey)
	if err != nil {
		utils.LogDebug("创建OSS客户端失败: %v", err)
		utils.InternalServerError(c, "创建OSS客户端失败")
		return
	}

	// 获取Bucket
	bucket, err := client.Bucket(bucketName)
	if err != nil {
		utils.LogDebug("获取Bucket失败: %v", err)
		utils.InternalServerError(c, "获取Bucket失败")
		return
	}

	// 生成唯一的文件名，头像上传到avatars目录
	timestamp := time.Now().Unix()
	objectKey := fmt.Sprintf("avatars/%d_%s", timestamp, file.Filename)

	// 打开上传的文件
	src, err := file.Open()
	if err != nil {
		utils.LogDebug("打开文件失败: %v", err)
		utils.InternalServerError(c, "打开文件失败")
		return
	}
	defer src.Close()

	// 上传到OSS
	err = bucket.PutObject(objectKey, src)
	if err != nil {
		utils.LogDebug("上传文件到OSS失败: %v", err)
		utils.InternalServerError(c, "上传文件失败")
		return
	}

	// 构建文件URL - 优先使用CDN域名
	cdnDomain := os.Getenv("S3_CDN_DOMAIN")
	if cdnDomain == "" {
		cdnDomain = viper.GetString("S3_CDN_DOMAIN")
	}
	var fileURL string
	if cdnDomain != "" {
		fileURL = fmt.Sprintf("https://%s/%s", cdnDomain, objectKey)
	} else {
		fileURL = fmt.Sprintf("https://%s.%s/%s", bucketName, strings.TrimPrefix(endpoint, "https://"), objectKey)
	}

	utils.SuccessWithMessage(c, "头像上传成功", gin.H{
		"url":       fileURL,
		"file_name": file.Filename,
		"size":      file.Size,
	})
}

// UploadVideoChunk 上传视频分片到阿里云OSS（分片并发上传）
func (ctrl *UploadController) UploadVideoChunk(c *gin.Context) {
	// 获取分片信息
	chunkIndexStr := c.PostForm("chunk_index")
	totalChunksStr := c.PostForm("total_chunks")
	fileName := c.PostForm("file_name")
	uploadId := c.PostForm("upload_id")

	if chunkIndexStr == "" || totalChunksStr == "" || fileName == "" {
		utils.BadRequest(c, "缺少必要参数: chunk_index, total_chunks, file_name")
		return
	}

	chunkIndex, err := strconv.Atoi(chunkIndexStr)
	if err != nil {
		utils.BadRequest(c, "chunk_index 格式错误")
		return
	}

	totalChunks, err := strconv.Atoi(totalChunksStr)
	if err != nil {
		utils.BadRequest(c, "total_chunks 格式错误")
		return
	}

	// 验证文件类型
	ext := strings.ToLower(filepath.Ext(fileName))
	allowedExts := map[string]bool{
		".mp4":  true,
		".mov":  true,
		".avi":  true,
		".mkv":  true,
		".flv":  true,
		".wmv":  true,
		".webm": true,
		".m4v":  true,
	}
	if !allowedExts[ext] {
		utils.BadRequest(c, "不支持的视频格式，仅支持 mp4, mov, avi, mkv, flv, wmv, webm, m4v")
		return
	}

	// 获取上传的文件
	file, err := c.FormFile("chunk")
	if err != nil {
		utils.BadRequest(c, "获取分片文件失败: "+err.Error())
		return
	}

	// 验证分片大小（最大100MB）
	if file.Size > 100*1024*1024 {
		utils.BadRequest(c, "分片大小不能超过100MB")
		return
	}

	// 读取OSS配置
	endpoint := os.Getenv("S3_ENDPOINT")
	if endpoint == "" {
		endpoint = viper.GetString("S3_ENDPOINT")
	}

	accessKey := os.Getenv("S3_ACCESS_KEY")
	if accessKey == "" {
		accessKey = viper.GetString("S3_ACCESS_KEY")
	}

	secretKey := os.Getenv("S3_SECRET_KEY")
	if secretKey == "" {
		secretKey = viper.GetString("S3_SECRET_KEY")
	}

	bucketName := os.Getenv("S3_BUCKET")
	if bucketName == "" {
		bucketName = viper.GetString("S3_BUCKET")
	}

	if endpoint == "" || accessKey == "" || secretKey == "" || bucketName == "" {
		utils.LogDebug("OSS配置缺失: endpoint=%s, accessKey=%s, secretKey=%s, bucket=%s",
			endpoint, accessKey, secretKey, bucketName)
		utils.InternalServerError(c, "OSS配置未设置")
		return
	}

	// 创建OSS客户端
	client, err := oss.New(endpoint, accessKey, secretKey)
	if err != nil {
		utils.LogDebug("创建OSS客户端失败: %v", err)
		utils.InternalServerError(c, "创建OSS客户端失败")
		return
	}

	// 获取Bucket
	bucket, err := client.Bucket(bucketName)
	if err != nil {
		utils.LogDebug("获取Bucket失败: %v", err)
		utils.InternalServerError(c, "获取Bucket失败")
		return
	}

	// 生成唯一的文件名（使用文件hash或timestamp确保唯一性）
	// 如果提供了object_key，使用它；否则生成新的（仅第一个分片）
	objectKey := c.PostForm("object_key")
	if objectKey == "" {
		// 如果不是第一个分片且没有提供objectKey，说明有问题
		if chunkIndex > 0 {
			utils.BadRequest(c, "非第一个分片必须提供object_key")
			return
		}
		// 只有第一个分片才生成新的objectKey
		// 提取纯文件名（去除路径，兼容Windows和Unix路径）
		baseFileName := filepath.Base(fileName)
		timestamp := time.Now().Unix()
		objectKey = fmt.Sprintf("videos/%d_%s", timestamp, baseFileName)
	}

	// 打开分片文件
	src, err := file.Open()
	if err != nil {
		utils.LogDebug("打开分片文件失败: %v", err)
		utils.InternalServerError(c, "打开分片文件失败")
		return
	}
	defer src.Close()

	// 如果是第一个分片，初始化分片上传
	if chunkIndex == 0 && uploadId == "" {
		// 根据文件扩展名设置Content-Type
		contentType := "video/mp4" // 默认值
		ext := strings.ToLower(filepath.Ext(fileName))
		contentTypeMap := map[string]string{
			".mp4":  "video/mp4",
			".mov":  "video/quicktime",
			".avi":  "video/x-msvideo",
			".mkv":  "video/x-matroska",
			".flv":  "video/x-flv",
			".wmv":  "video/x-ms-wmv",
			".webm": "video/webm",
			".m4v":  "video/mp4",
		}
		if ct, ok := contentTypeMap[ext]; ok {
			contentType = ct
		}

		// 设置对象元数据，包括Content-Type和Content-Disposition
		options := []oss.Option{
			oss.ContentType(contentType),
			oss.ContentDisposition("inline"), // 设置为inline以便浏览器直接预览
		}

		imur, err := bucket.InitiateMultipartUpload(objectKey, options...)
		if err != nil {
			utils.LogDebug("初始化分片上传失败: %v", err)
			utils.InternalServerError(c, "初始化分片上传失败")
			return
		}
		uploadId = imur.UploadID
	}

	// 非第一个分片必须提供uploadId
	if chunkIndex > 0 && uploadId == "" {
		utils.BadRequest(c, "非第一个分片必须提供upload_id")
		return
	}

	if uploadId == "" {
		utils.BadRequest(c, "upload_id 不能为空")
		return
	}

	// 上传分片
	_, err = bucket.UploadPart(oss.InitiateMultipartUploadResult{
		Bucket:   bucketName,
		Key:      objectKey,
		UploadID: uploadId,
	}, src, file.Size, chunkIndex+1)
	if err != nil {
		utils.LogDebug("上传分片失败: chunkIndex=%d, error=%v", chunkIndex, err)
		utils.InternalServerError(c, fmt.Sprintf("上传分片失败: %v", err))
		return
	}

	// 如果是最后一个分片，完成分片上传
	if chunkIndex == totalChunks-1 {
		// 获取所有已上传的分片
		partsResult, err := bucket.ListUploadedParts(oss.InitiateMultipartUploadResult{
			Bucket:   bucketName,
			Key:      objectKey,
			UploadID: uploadId,
		})
		if err != nil {
			utils.LogDebug("获取已上传分片列表失败: %v", err)
			utils.InternalServerError(c, "获取已上传分片列表失败")
			return
		}

		// 将UploadedPart转换为UploadPart
		parts := make([]oss.UploadPart, len(partsResult.UploadedParts))
		for i, uploadedPart := range partsResult.UploadedParts {
			parts[i] = oss.UploadPart{
				PartNumber: uploadedPart.PartNumber,
				ETag:       uploadedPart.ETag,
			}
		}

		// 完成分片上传
		_, err = bucket.CompleteMultipartUpload(oss.InitiateMultipartUploadResult{
			Bucket:   bucketName,
			Key:      objectKey,
			UploadID: uploadId,
		}, parts)
		if err != nil {
			utils.LogDebug("完成分片上传失败: %v", err)
			utils.InternalServerError(c, "完成分片上传失败")
			return
		}

		// 构建文件URL - 优先使用CDN域名
		cdnDomain := os.Getenv("S3_CDN_DOMAIN")
		if cdnDomain == "" {
			cdnDomain = viper.GetString("S3_CDN_DOMAIN")
		}
		var fileURL string
		if cdnDomain != "" {
			fileURL = fmt.Sprintf("https://%s/%s", cdnDomain, objectKey)
		} else {
			fileURL = fmt.Sprintf("https://%s.%s/%s", bucketName, strings.TrimPrefix(endpoint, "https://"), objectKey)
		}

		// 提取纯文件名（去除路径）
		baseFileName := filepath.Base(fileName)

		utils.SuccessWithMessage(c, "视频上传成功", gin.H{
			"url":       fileURL,
			"file_name": baseFileName,
			"upload_id": uploadId,
			"completed": true,
		})
	} else {
		// 返回upload_id和object_key供后续分片使用
		utils.SuccessWithMessage(c, "分片上传成功", gin.H{
			"upload_id":   uploadId,
			"object_key":  objectKey,
			"chunk_index": chunkIndex,
			"completed":   false,
		})
	}
}

// UploadVideoChunksConcurrent 并发上传视频分片到OSS（服务器端优化）
func (ctrl *UploadController) uploadVideoChunksConcurrent(bucket *oss.Bucket, bucketName string, objectKey string, uploadId string, chunks []io.Reader, chunkSizes []int64) error {
	var wg sync.WaitGroup
	errChan := make(chan error, len(chunks))
	semaphore := make(chan struct{}, 16) // 16核并发控制

	for i, chunk := range chunks {
		wg.Add(1)
		semaphore <- struct{}{} // 获取信号量

		go func(index int, chunkReader io.Reader, size int64) {
			defer wg.Done()
			defer func() { <-semaphore }() // 释放信号量

			_, err := bucket.UploadPart(oss.InitiateMultipartUploadResult{
				Bucket:   bucketName,
				Key:      objectKey,
				UploadID: uploadId,
			}, chunkReader, size, index+1)

			if err != nil {
				errChan <- fmt.Errorf("分片 %d 上传失败: %v", index+1, err)
				return
			}

		}(i, chunk, chunkSizes[i])
	}

	wg.Wait()
	close(errChan)

	// 检查是否有错误
	if len(errChan) > 0 {
		var errs []string
		for err := range errChan {
			errs = append(errs, err.Error())
		}
		return fmt.Errorf("分片上传失败: %s", strings.Join(errs, "; "))
	}

	return nil
}
