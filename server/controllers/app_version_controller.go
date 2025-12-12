package controllers

import (
	"fmt"
	"os"
	"strconv"
	"strings"

	"youdu-server/db"
	"youdu-server/models"
	"youdu-server/utils"

	"github.com/aliyun/aliyun-oss-go-sdk/oss"
	"github.com/gin-gonic/gin"
	"github.com/spf13/viper"
)

// AppVersionController 应用版本控制器
type AppVersionController struct {
	repo *models.AppVersionRepository
}

// NewAppVersionController 创建版本控制器
func NewAppVersionController() *AppVersionController {
	return &AppVersionController{
		repo: models.NewAppVersionRepository(db.DB),
	}
}

// CreateVersion 创建版本
func (ctrl *AppVersionController) CreateVersion(c *gin.Context) {
	var req models.CreateAppVersionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "请求参数错误: "+err.Error())
		return
	}

	// 验证平台
	req.Platform = strings.ToLower(req.Platform)
	if req.Platform != "windows" && req.Platform != "android" && req.Platform != "ios" {
		utils.BadRequest(c, "平台必须是 windows, android 或 ios")
		return
	}

	// 检查版本是否已存在
	existing, _ := ctrl.repo.FindByVersionAndPlatform(req.Version, req.Platform)
	if existing != nil {
		utils.BadRequest(c, fmt.Sprintf("版本 %s (%s) 已存在", req.Version, req.Platform))
		return
	}

	// 获取创建人（可选）
	createdBy := ""
	if userID, exists := c.Get("user_id"); exists {
		createdBy = fmt.Sprintf("%v", userID)
	}

	version, err := ctrl.repo.Create(req, createdBy)
	if err != nil {
		utils.InternalServerError(c, "创建版本失败: "+err.Error())
		return
	}

	utils.Success(c, version)
}


// GetVersion 获取版本详情
func (ctrl *AppVersionController) GetVersion(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.BadRequest(c, "无效的版本ID")
		return
	}

	version, err := ctrl.repo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "版本不存在")
		return
	}

	utils.Success(c, version)
}

// GetLatestVersion 获取指定平台的最新版本
func (ctrl *AppVersionController) GetLatestVersion(c *gin.Context) {
	platform := strings.ToLower(c.Query("platform"))
	if platform == "" {
		utils.BadRequest(c, "请指定平台参数")
		return
	}

	if platform != "windows" && platform != "android" && platform != "ios" {
		utils.BadRequest(c, "平台必须是 windows, android 或 ios")
		return
	}

	version, err := ctrl.repo.GetLatestByPlatform(platform)
	if err != nil {
		utils.NotFound(c, "暂无可用版本")
		return
	}

	utils.Success(c, version)
}

// ListVersions 获取版本列表
func (ctrl *AppVersionController) ListVersions(c *gin.Context) {
	platform := strings.ToLower(c.Query("platform"))
	status := c.Query("status")
	pageStr := c.DefaultQuery("page", "1")
	pageSizeStr := c.DefaultQuery("page_size", "20")

	page, _ := strconv.Atoi(pageStr)
	pageSize, _ := strconv.Atoi(pageSizeStr)

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	versions, total, err := ctrl.repo.List(platform, status, page, pageSize)
	if err != nil {
		utils.InternalServerError(c, "获取版本列表失败: "+err.Error())
		return
	}

	utils.Success(c, gin.H{
		"list":      versions,
		"total":     total,
		"page":      page,
		"page_size": pageSize,
	})
}

// UpdateVersion 更新版本信息
func (ctrl *AppVersionController) UpdateVersion(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.BadRequest(c, "无效的版本ID")
		return
	}

	var req models.UpdateAppVersionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "请求参数错误: "+err.Error())
		return
	}

	// 检查版本是否存在
	_, err = ctrl.repo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "版本不存在")
		return
	}

	if err := ctrl.repo.Update(id, req); err != nil {
		utils.InternalServerError(c, "更新版本失败: "+err.Error())
		return
	}

	utils.Success(c, gin.H{"message": "更新成功"})
}

// PublishVersion 发布版本
func (ctrl *AppVersionController) PublishVersion(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.BadRequest(c, "无效的版本ID")
		return
	}

	version, err := ctrl.repo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "版本不存在")
		return
	}

	if version.Status == "published" {
		utils.BadRequest(c, "版本已发布")
		return
	}

	if err := ctrl.repo.Publish(id); err != nil {
		utils.InternalServerError(c, "发布版本失败: "+err.Error())
		return
	}

	utils.Success(c, gin.H{"message": "发布成功"})
}

// DeprecateVersion 废弃版本
func (ctrl *AppVersionController) DeprecateVersion(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.BadRequest(c, "无效的版本ID")
		return
	}

	if err := ctrl.repo.Deprecate(id); err != nil {
		utils.InternalServerError(c, "废弃版本失败: "+err.Error())
		return
	}

	utils.Success(c, gin.H{"message": "版本已废弃"})
}

// DeleteVersion 删除版本
func (ctrl *AppVersionController) DeleteVersion(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		utils.BadRequest(c, "无效的版本ID")
		return
	}

	version, err := ctrl.repo.FindByID(id)
	if err != nil {
		utils.NotFound(c, "版本不存在")
		return
	}

	// 只有oss类型才删除OSS文件，url类型（如iOS分发地址）不需要删除
	if version.DistributionType == "oss" && version.OSSObjectKey != nil && *version.OSSObjectKey != "" {
		if err := ctrl.deleteOSSFile(*version.OSSObjectKey); err != nil {
			// 记录错误但不阻止删除
			fmt.Printf("删除OSS文件失败: %v\n", err)
		}
	}

	if err := ctrl.repo.Delete(id); err != nil {
		utils.InternalServerError(c, "删除版本失败: "+err.Error())
		return
	}

	utils.Success(c, gin.H{"message": "删除成功"})
}

// CheckUpdate 检查更新（客户端调用）
func (ctrl *AppVersionController) CheckUpdate(c *gin.Context) {
	platform := strings.ToLower(c.Query("platform"))
	currentVersion := c.Query("version")

	if platform == "" || currentVersion == "" {
		utils.BadRequest(c, "请提供 platform 和 version 参数")
		return
	}

	if platform != "windows" && platform != "android" && platform != "ios" {
		utils.BadRequest(c, "平台必须是 windows, android 或 ios")
		return
	}

	latestVersion, err := ctrl.repo.GetLatestByPlatform(platform)
	if err != nil {
		utils.Success(c, gin.H{
			"has_update": false,
			"message":    "暂无可用更新",
		})
		return
	}

	// 比较版本号
	hasUpdate := compareVersions(latestVersion.Version, currentVersion) > 0
	needForceUpdate := false

	if hasUpdate && latestVersion.MinSupportedVersion != nil {
		// 检查是否需要强制更新
		if compareVersions(*latestVersion.MinSupportedVersion, currentVersion) > 0 {
			needForceUpdate = true
		}
	}

	if hasUpdate || latestVersion.IsForceUpdate {
		needForceUpdate = needForceUpdate || latestVersion.IsForceUpdate
	}

	utils.Success(c, gin.H{
		"has_update":    hasUpdate,
		"force_update":  needForceUpdate,
		"latest":        latestVersion,
	})
}

// deleteOSSFile 删除OSS文件
func (ctrl *AppVersionController) deleteOSSFile(objectKey string) error {
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
		return fmt.Errorf("OSS配置未设置")
	}

	client, err := oss.New(endpoint, accessKey, secretKey)
	if err != nil {
		return fmt.Errorf("创建OSS客户端失败: %w", err)
	}

	bucket, err := client.Bucket(bucketName)
	if err != nil {
		return fmt.Errorf("获取Bucket失败: %w", err)
	}

	return bucket.DeleteObject(objectKey)
}

// GetAllPlatformLatestVersions 获取所有平台的最新版本（公开接口）
func (ctrl *AppVersionController) GetAllPlatformLatestVersions(c *gin.Context) {
	versions, err := ctrl.repo.GetLatestVersionsForAllPlatforms()
	if err != nil {
		utils.InternalServerError(c, "获取版本信息失败: "+err.Error())
		return
	}

	// 直接返回各平台的版本信息，不包含 platforms 字段
	response := gin.H{}

	// 添加各平台的版本信息
	if v, ok := versions["windows"]; ok {
		response["windows"] = v
	}
	if v, ok := versions["android"]; ok {
		response["android"] = v
	}
	if v, ok := versions["ios"]; ok {
		response["ios"] = v
	}

	utils.Success(c, response)
}

// compareVersions 比较版本号 (返回: 1 表示 v1 > v2, -1 表示 v1 < v2, 0 表示相等)
func compareVersions(v1, v2 string) int {
	parts1 := strings.Split(v1, ".")
	parts2 := strings.Split(v2, ".")

	maxLen := len(parts1)
	if len(parts2) > maxLen {
		maxLen = len(parts2)
	}

	for i := 0; i < maxLen; i++ {
		var num1, num2 int
		if i < len(parts1) {
			num1, _ = strconv.Atoi(parts1[i])
		}
		if i < len(parts2) {
			num2, _ = strconv.Atoi(parts2[i])
		}

		if num1 > num2 {
			return 1
		}
		if num1 < num2 {
			return -1
		}
	}

	return 0
}
