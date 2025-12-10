package controllers

import (
	"database/sql"
	"strconv"
	"youdu-server/db"
	"youdu-server/models"
	"youdu-server/utils"

	"github.com/gin-gonic/gin"
)

// FavoriteCommonController 常用联系人和群组控制器
type FavoriteCommonController struct {
	repo *models.FavoriteCommonRepository
}

// NewFavoriteCommonController 创建常用联系人和群组控制器
func NewFavoriteCommonController() *FavoriteCommonController {
	return &FavoriteCommonController{
		repo: models.NewFavoriteCommonRepository(db.DB),
	}
}

// ===== 常用联系人相关API =====

// AddFavoriteContact 添加常用联系人
// @Summary 添加常用联系人
// @Description 将联系人添加到常用联系人列表
// @Tags 常用联系人
// @Accept json
// @Produce json
// @Param body body models.AddFavoriteRequest true "联系人ID"
// @Success 200 {object} utils.Response
// @Router /api/favorite-contacts [post]
func (ctrl *FavoriteCommonController) AddFavoriteContact(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "未授权")
		return
	}

	var req models.AddFavoriteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "参数错误："+err.Error())
		return
	}

	if req.ContactID <= 0 {
		utils.BadRequest(c, "联系人ID不能为空")
		return
	}

	// 检查联系人是否存在
	userRepo := models.NewUserRepository(db.DB)
	_, err := userRepo.FindByID(req.ContactID)
	if err != nil {
		if err == sql.ErrNoRows {
			utils.NotFound(c, "联系人不存在")
		} else {
			utils.InternalServerError(c, "查询联系人失败："+err.Error())
		}
		return
	}

	// 添加常用联系人
	err = ctrl.repo.AddFavoriteContact(userID.(int), req.ContactID)
	if err != nil {
		utils.InternalServerError(c, "添加常用联系人失败："+err.Error())
		return
	}

	utils.SuccessWithMessage(c, "添加常用联系人成功", nil)
}

// RemoveFavoriteContact 移除常用联系人
// @Summary 移除常用联系人
// @Description 从常用联系人列表中移除联系人
// @Tags 常用联系人
// @Produce json
// @Param contact_id path int true "联系人ID"
// @Success 200 {object} utils.Response
// @Router /api/favorite-contacts/{contact_id} [delete]
func (ctrl *FavoriteCommonController) RemoveFavoriteContact(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "未授权")
		return
	}

	contactIDStr := c.Param("contact_id")
	contactID, err := strconv.Atoi(contactIDStr)
	if err != nil {
		utils.BadRequest(c, "联系人ID格式错误")
		return
	}

	err = ctrl.repo.RemoveFavoriteContact(userID.(int), contactID)
	if err != nil {
		utils.InternalServerError(c, "移除常用联系人失败："+err.Error())
		return
	}

	utils.SuccessWithMessage(c, "移除常用联系人成功", nil)
}

// GetFavoriteContacts 获取常用联系人列表
// @Summary 获取常用联系人列表
// @Description 获取当前用户的所有常用联系人
// @Tags 常用联系人
// @Produce json
// @Success 200 {object} utils.Response{data=[]models.FavoriteContactDetail}
// @Router /api/favorite-contacts [get]
func (ctrl *FavoriteCommonController) GetFavoriteContacts(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "未授权")
		return
	}

	contacts, err := ctrl.repo.GetFavoriteContacts(userID.(int))
	if err != nil {
		utils.InternalServerError(c, "获取常用联系人列表失败："+err.Error())
		return
	}

	if contacts == nil {
		contacts = []models.FavoriteContactDetail{}
	}

	utils.SuccessWithMessage(c, "获取常用联系人列表成功", contacts)
}

// CheckFavoriteContact 检查是否为常用联系人
// @Summary 检查是否为常用联系人
// @Description 检查指定联系人是否在常用联系人列表中
// @Tags 常用联系人
// @Produce json
// @Param contact_id path int true "联系人ID"
// @Success 200 {object} utils.Response{data=bool}
// @Router /api/favorite-contacts/check/{contact_id} [get]
func (ctrl *FavoriteCommonController) CheckFavoriteContact(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "未授权")
		return
	}

	contactIDStr := c.Param("contact_id")
	contactID, err := strconv.Atoi(contactIDStr)
	if err != nil {
		utils.BadRequest(c, "联系人ID格式错误")
		return
	}

	isFavorite, err := ctrl.repo.IsFavoriteContact(userID.(int), contactID)
	if err != nil {
		utils.InternalServerError(c, "检查常用联系人失败："+err.Error())
		return
	}

	utils.SuccessWithMessage(c, "检查完成", gin.H{"is_favorite": isFavorite})
}

// ===== 常用群组相关API =====

// AddFavoriteGroup 添加常用群组
// @Summary 添加常用群组
// @Description 将群组添加到常用群组列表
// @Tags 常用群组
// @Accept json
// @Produce json
// @Param body body models.AddFavoriteRequest true "群组ID"
// @Success 200 {object} utils.Response
// @Router /api/favorite-groups [post]
func (ctrl *FavoriteCommonController) AddFavoriteGroup(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "未授权")
		return
	}

	var req models.AddFavoriteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "参数错误："+err.Error())
		return
	}

	if req.GroupID <= 0 {
		utils.BadRequest(c, "群组ID不能为空")
		return
	}

	// 检查群组是否存在
	groupRepo := models.NewGroupRepository(db.DB)
	_, err := groupRepo.GetGroupByID(req.GroupID)
	if err != nil {
		if err == sql.ErrNoRows {
			utils.NotFound(c, "群组不存在")
		} else {
			utils.InternalServerError(c, "查询群组失败："+err.Error())
		}
		return
	}

	// 检查用户是否为群组成员
	_, err = groupRepo.GetUserGroupRole(req.GroupID, userID.(int))
	if err != nil {
		if err == sql.ErrNoRows {
			utils.Forbidden(c, "您不是该群组成员")
		} else {
			utils.InternalServerError(c, "检查群组成员失败："+err.Error())
		}
		return
	}

	// 添加常用群组
	err = ctrl.repo.AddFavoriteGroup(userID.(int), req.GroupID)
	if err != nil {
		utils.InternalServerError(c, "添加常用群组失败："+err.Error())
		return
	}

	utils.SuccessWithMessage(c, "添加常用群组成功", nil)
}

// RemoveFavoriteGroup 移除常用群组
// @Summary 移除常用群组
// @Description 从常用群组列表中移除群组
// @Tags 常用群组
// @Produce json
// @Param group_id path int true "群组ID"
// @Success 200 {object} utils.Response
// @Router /api/favorite-groups/{group_id} [delete]
func (ctrl *FavoriteCommonController) RemoveFavoriteGroup(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "未授权")
		return
	}

	groupIDStr := c.Param("group_id")
	groupID, err := strconv.Atoi(groupIDStr)
	if err != nil {
		utils.BadRequest(c, "群组ID格式错误")
		return
	}

	err = ctrl.repo.RemoveFavoriteGroup(userID.(int), groupID)
	if err != nil {
		utils.InternalServerError(c, "移除常用群组失败："+err.Error())
		return
	}

	utils.SuccessWithMessage(c, "移除常用群组成功", nil)
}

// GetFavoriteGroups 获取常用群组列表
// @Summary 获取常用群组列表
// @Description 获取当前用户的所有常用群组
// @Tags 常用群组
// @Produce json
// @Success 200 {object} utils.Response{data=[]models.FavoriteGroupDetail}
// @Router /api/favorite-groups [get]
func (ctrl *FavoriteCommonController) GetFavoriteGroups(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "未授权")
		return
	}

	groups, err := ctrl.repo.GetFavoriteGroups(userID.(int))
	if err != nil {
		utils.InternalServerError(c, "获取常用群组列表失败："+err.Error())
		return
	}

	if groups == nil {
		groups = []models.FavoriteGroupDetail{}
	}

	utils.SuccessWithMessage(c, "获取常用群组列表成功", groups)
}

// CheckFavoriteGroup 检查是否为常用群组
// @Summary 检查是否为常用群组
// @Description 检查指定群组是否在常用群组列表中
// @Tags 常用群组
// @Produce json
// @Param group_id path int true "群组ID"
// @Success 200 {object} utils.Response{data=bool}
// @Router /api/favorite-groups/check/{group_id} [get]
func (ctrl *FavoriteCommonController) CheckFavoriteGroup(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "未授权")
		return
	}

	groupIDStr := c.Param("group_id")
	groupID, err := strconv.Atoi(groupIDStr)
	if err != nil {
		utils.BadRequest(c, "群组ID格式错误")
		return
	}

	isFavorite, err := ctrl.repo.IsFavoriteGroup(userID.(int), groupID)
	if err != nil {
		utils.InternalServerError(c, "检查常用群组失败："+err.Error())
		return
	}

	utils.SuccessWithMessage(c, "检查完成", gin.H{"is_favorite": isFavorite})
}
