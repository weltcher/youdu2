package controllers

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	// "time"

	"github.com/gin-gonic/gin"
	"youdu-server/db"
)

type DeviceController struct{}

func NewDeviceController() *DeviceController {
	return &DeviceController{}
}

// AES加密密钥（与客户端保持一致）
const deviceEncryptionKey = "uDrAPQyLzXB3G1"

// EncryptedDeviceRequest 加密的设备注册请求结构
type EncryptedDeviceRequest struct {
	EncryptedData string `json:"encrypted_data" binding:"required"` // Base64编码的AES加密数据
}

// RegisterDeviceRequest 设备注册请求结构（解密后的数据）
type RegisterDeviceRequest struct {
	UUID        string                 `json:"uuid" binding:"required"`         // 数据库密钥UUID
	Platform    string                 `json:"platform" binding:"required"`     // 系统类型：android, ios, windows, macos, linux
	SystemInfo  map[string]interface{} `json:"system_info" binding:"required"`  // 系统详细信息
	InstalledAt string                 `json:"installed_at" binding:"required"` // 安装时间（ISO8601格式字符串）
}

// decryptDeviceData 解密设备数据
// 使用 AES-256-CBC 算法解密，密钥使用 SHA-256 哈希后的值
func decryptDeviceData(encryptedData string) ([]byte, error) {
	// 1. Base64解码
	ciphertext, err := base64.StdEncoding.DecodeString(encryptedData)
	if err != nil {
		return nil, fmt.Errorf("Base64解码失败: %v", err)
	}

	// 2. 生成32字节密钥（AES-256需要32字节）
	// 使用SHA-256对原始密钥进行哈希
	hash := sha256.Sum256([]byte(deviceEncryptionKey))
	key := hash[:]

	// 3. 检查数据长度
	if len(ciphertext) < aes.BlockSize {
		return nil, errors.New("加密数据太短")
	}

	// 4. 创建AES cipher
	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, fmt.Errorf("创建AES cipher失败: %v", err)
	}

	// 5. 提取IV（前16字节）
	iv := ciphertext[:aes.BlockSize]
	ciphertext = ciphertext[aes.BlockSize:]

	// 6. 创建CBC解密器
	mode := cipher.NewCBCDecrypter(block, iv)

	// 7. 解密
	plaintext := make([]byte, len(ciphertext))
	mode.CryptBlocks(plaintext, ciphertext)

	// 8. 去除PKCS7填充
	plaintext, err = pkcs7Unpad(plaintext)
	if err != nil {
		return nil, fmt.Errorf("去除填充失败: %v", err)
	}

	return plaintext, nil
}

// pkcs7Unpad 去除PKCS7填充
func pkcs7Unpad(data []byte) ([]byte, error) {
	length := len(data)
	if length == 0 {
		return nil, errors.New("数据为空")
	}

	padding := int(data[length-1])
	if padding > length || padding > aes.BlockSize {
		return nil, errors.New("无效的填充")
	}

	// 验证填充
	for i := 0; i < padding; i++ {
		if data[length-1-i] != byte(padding) {
			return nil, errors.New("填充验证失败")
		}
	}

	return data[:length-padding], nil
}

// RegisterDevice 注册设备信息（支持AES-256加密）
// @Summary 注册设备信息
// @Description 首次启动时注册设备信息，包括UUID、平台、系统信息等。请求数据使用AES-256加密
// @Tags Device
// @Accept json
// @Produce json
// @Param request body EncryptedDeviceRequest true "加密的设备注册信息"
// @Success 200 {object} map[string]interface{}
// @Failure 400 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/device/register [post]
func (ctrl *DeviceController) RegisterDevice(c *gin.Context) {
	// 1. 接收加密的请求数据
	var encryptedReq EncryptedDeviceRequest
	if err := c.ShouldBindJSON(&encryptedReq); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "请求参数错误: " + err.Error(),
		})
		return
	}

	// 2. 解密数据
	decryptedData, err := decryptDeviceData(encryptedReq.EncryptedData)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "数据解密失败: " + err.Error(),
		})
		return
	}

	// 3. 解析解密后的JSON数据
	var req RegisterDeviceRequest
	if err := json.Unmarshal(decryptedData, &req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    400,
			"message": "数据格式错误: " + err.Error(),
		})
		return
	}

	// 获取客户端IP地址
	requestIP := c.ClientIP()
	// 将系统信息转换为JSON
	systemInfoJSON, err := json.Marshal(req.SystemInfo)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    500,
			"message": "系统信息序列化失败: " + err.Error(),
		})
		return
	}

	// 检查UUID是否已存在
	var existingID int
	err = db.DB.QueryRow(
		"SELECT id FROM device_registrations WHERE uuid = $1",
		req.UUID,
	).Scan(&existingID)

	if err == nil {
		// UUID已存在，更新记录
		_, err = db.DB.Exec(`
			UPDATE device_registrations 
			SET request_ip = $1, 
			    platform = $2, 
			    system_info = $3, 
			    updated_at = CURRENT_TIMESTAMP
			WHERE uuid = $4
		`, requestIP, req.Platform, systemInfoJSON, req.UUID)

		if err != nil {
			fmt.Printf("❌ [设备注册] 更新失败: %v\n", err)
			c.JSON(http.StatusInternalServerError, gin.H{
				"code":    500,
				"message": "更新设备信息失败: " + err.Error(),
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"code":    200,
			"message": "设备信息更新成功",
		})
		return
	}

	// UUID不存在，插入新记录
	var deviceID int
	err = db.DB.QueryRow(`
		INSERT INTO device_registrations (uuid, request_ip, platform, system_info, installed_at)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING id
	`, req.UUID, requestIP, req.Platform, systemInfoJSON, req.InstalledAt).Scan(&deviceID)

	if err != nil {
		fmt.Printf("❌ [设备注册] 插入失败: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    500,
			"message": "注册设备信息失败: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "设备注册成功",
	})
}

// GetDeviceStats 获取设备统计信息（可选功能，用于管理后台）
// @Summary 获取设备统计信息
// @Description 获取各平台的设备注册统计
// @Tags Device
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Failure 500 {object} map[string]interface{}
// @Router /api/device/stats [get]
func (ctrl *DeviceController) GetDeviceStats(c *gin.Context) {
	// 统计各平台的设备数量
	rows, err := db.DB.Query(`
		SELECT platform, COUNT(*) as count
		FROM device_registrations
		GROUP BY platform
		ORDER BY count DESC
	`)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    500,
			"message": "查询统计信息失败: " + err.Error(),
		})
		return
	}
	defer rows.Close()

	stats := make(map[string]int)
	totalCount := 0

	for rows.Next() {
		var platform string
		var count int
		if err := rows.Scan(&platform, &count); err != nil {
			continue
		}
		stats[platform] = count
		totalCount += count
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "获取统计信息成功",
		"data": gin.H{
			"total":     totalCount,
			"platforms": stats,
		},
	})
}
