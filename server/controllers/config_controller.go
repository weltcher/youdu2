package controllers

import (
	"database/sql"

	"youdu-server/db"
	"youdu-server/models"
	"youdu-server/utils"

	"github.com/gin-gonic/gin"
)

// ConfigController 配置控制器
type ConfigController struct {
	settingRepo *models.ServerSettingRepository
}

// NewConfigController 创建配置控制器
func NewConfigController() *ConfigController {
	return &ConfigController{
		settingRepo: models.NewServerSettingRepository(db.DB),
	}
}

// GetServerSettings 获取服务器设置
func (ctrl *ConfigController) GetServerSettings(c *gin.Context) {
	settings, err := ctrl.settingRepo.GetAll()
	if err != nil {
		utils.LogDebug("获取服务器设置失败: %v", err)
		utils.InternalServerError(c, "获取设置失败")
		return
	}

	// 转换为map格式
	settingsMap := make(map[string]interface{})
	for _, setting := range settings {
		settingsMap[setting.Key] = gin.H{
			"value":       setting.Value,
			"description": setting.Description,
			"updated_at":  setting.UpdatedAt,
		}
	}

	utils.Success(c, settingsMap)
}

// GetServerSetting 获取单个服务器设置
func (ctrl *ConfigController) GetServerSetting(c *gin.Context) {
	key := c.Param("key")
	if key == "" {
		utils.BadRequest(c, "缺少配置键")
		return
	}

	setting, err := ctrl.settingRepo.GetByKey(key)
	if err != nil {
		if err == sql.ErrNoRows {
			utils.NotFound(c, "配置不存在")
			return
		}
		utils.LogDebug("获取服务器设置失败: %v", err)
		utils.InternalServerError(c, "获取设置失败")
		return
	}

	utils.Success(c, setting)
}

// UpdateServerSetting 更新服务器设置
func (ctrl *ConfigController) UpdateServerSetting(c *gin.Context) {
	var req struct {
		Key         string `json:"key" binding:"required"`
		Value       string `json:"value" binding:"required"`
		Description string `json:"description"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "请求参数错误: "+err.Error())
		return
	}

	// 检查设置是否存在
	existSetting, err := ctrl.settingRepo.GetByKey(req.Key)
	if err != nil && err != sql.ErrNoRows {
		utils.LogDebug("查询设置失败: %v", err)
		utils.InternalServerError(c, "服务器错误")
		return
	}

	// 如果存在则更新，否则创建
	if existSetting != nil {
		err = ctrl.settingRepo.Update(req.Key, req.Value)
	} else {
		err = ctrl.settingRepo.Create(req.Key, req.Value, req.Description)
	}

	if err != nil {
		utils.LogDebug("更新设置失败: %v", err)
		utils.InternalServerError(c, "更新设置失败")
		return
	}

	utils.SuccessWithMessage(c, "设置更新成功", nil)
}

// BatchUpdateServerSettings 批量更新服务器设置
func (ctrl *ConfigController) BatchUpdateServerSettings(c *gin.Context) {
	var req map[string]string

	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "请求参数错误: "+err.Error())
		return
	}

	if len(req) == 0 {
		utils.BadRequest(c, "请提供要更新的设置")
		return
	}

	// 批量更新
	for key, value := range req {
		err := ctrl.settingRepo.Upsert(key, value, "")
		if err != nil {
			utils.LogDebug("更新设置 %s 失败: %v", key, err)
			utils.InternalServerError(c, "更新设置失败")
			return
		}
	}

	utils.SuccessWithMessage(c, "批量更新成功", nil)
}
