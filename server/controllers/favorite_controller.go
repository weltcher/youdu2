package controllers

import (
	"database/sql"
	"fmt"
	"net/http"
	"sort"
	"strconv"
	"strings"
	"youdu-server/db"
	"youdu-server/models"
	"youdu-server/utils"

	"github.com/gin-gonic/gin"
)

// FavoriteController 收藏控制器
type FavoriteController struct {
	favoriteRepo *models.FavoriteRepository
}

// NewFavoriteController 创建收藏控制器实例
func NewFavoriteController() *FavoriteController {
	favoriteRepo := models.NewFavoriteRepository(db.DB)
	return &FavoriteController{
		favoriteRepo: favoriteRepo,
	}
}

// CreateFavorite 创建收藏
// POST /api/favorites
func (ctrl *FavoriteController) CreateFavorite(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 401, "message": "未授权"})
		return
	}

	var req struct {
		MessageID int `json:"message_id" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误"})
		return
	}

	// 获取消息详情 - 先从 messages 表查找，如果找不到再从 group_messages 表查找
	// 注意：我们需要先确定消息类型，才能正确检查是否已收藏
	var message models.Message
	var senderID, receiverID int
	var senderName, receiverName, content, messageType string
	var fileName *string
	var isGroupMessage bool // 标记是否为群组消息
	var err error

	// 先尝试从 messages 表查找（私聊消息）
	query := `SELECT id, sender_id, receiver_id, sender_name, receiver_name, content, message_type, file_name 
	          FROM messages WHERE id = $1`
	err = db.DB.QueryRow(query, req.MessageID).Scan(
		&message.ID,
		&senderID,
		&receiverID,
		&senderName,
		&receiverName,
		&content,
		&messageType,
		&fileName,
	)

	// 如果在 messages 表中找不到（sql.ErrNoRows），尝试从 group_messages 表查找（群组消息）
	if err == sql.ErrNoRows {
		utils.LogDebug("消息ID %d 不在 messages 表中，尝试从 group_messages 表查找", req.MessageID)
		isGroupMessage = true
		groupQuery := `SELECT id, sender_id, sender_name, content, message_type, file_name 
		               FROM group_messages WHERE id = $1`
		var groupSenderID int
		var groupSenderName string
		err = db.DB.QueryRow(groupQuery, req.MessageID).Scan(
			&message.ID,
			&groupSenderID,
			&groupSenderName,
			&content,
			&messageType,
			&fileName,
		)
		if err != nil {
			if err == sql.ErrNoRows {
				utils.LogError("消息ID %d 在 messages 和 group_messages 表中都不存在", req.MessageID)
				c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "消息不存在"})
			} else {
				utils.LogError("查询群组消息失败 (message_id: %d): %v", req.MessageID, err)
				c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "查询消息失败"})
			}
			return
		}
		// 群组消息没有 receiver_id 和 receiver_name
		senderID = groupSenderID
		senderName = groupSenderName
		receiverID = 0
		receiverName = ""
		utils.LogDebug("成功从 group_messages 表找到消息ID %d，发送者: %s", req.MessageID, senderName)
	} else if err != nil {
		// 如果查询 messages 表时出现其他错误（非 ErrNoRows），直接返回错误
		utils.LogError("查询私聊消息失败 (message_id: %d): %v", req.MessageID, err)
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "查询消息失败"})
		return
	} else {
		// 成功从 messages 表找到，这是私聊消息
		isGroupMessage = false
	}

	// 设置消息对象
	message.SenderID = senderID
	message.ReceiverID = receiverID
	message.SenderName = senderName
	message.ReceiverName = receiverName
	message.Content = content
	message.MessageType = messageType
	message.FileName = fileName

	// 验证必要字段
	if senderName == "" {
		utils.LogError("发送者名称为空 (message_id: %d, sender_id: %d)", req.MessageID, senderID)
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "消息数据不完整：发送者名称为空"})
		return
	}
	if content == "" {
		utils.LogError("消息内容为空 (message_id: %d)", req.MessageID)
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "消息数据不完整：消息内容为空"})
		return
	}

	// 判断是否为群组消息
	// 如果是群组消息，message_id 设置为 NULL，因为外键约束 favorites_message_id_fkey 只指向 messages 表
	// 这样可以避免违反外键约束
	var messageIDForFavorite *int

	if isGroupMessage {
		// 这是群组消息，message_id 设置为 NULL 以避免外键约束冲突
		messageIDForFavorite = nil
		utils.LogDebug("准备创建收藏（群组消息）- user_id: %d, message_id: NULL (原ID: %d), sender_name: %s, message_type: %s",
			userID.(int), req.MessageID, senderName, messageType)

		// 检查群组消息是否已收藏（通过内容、发送者ID和用户ID）
		exists, favoriteID, checkErr := ctrl.favoriteRepo.CheckExistsByContent(userID.(int), content, senderID)
		if checkErr != nil {
			utils.LogError("检查群组消息收藏状态失败 (user_id: %d, sender_id: %d): %v", userID.(int), senderID, checkErr)
			c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "检查收藏状态失败"})
			return
		}

		if exists {
			// 如果已收藏，更新创建时间，让它在列表中排到最前面
			utils.LogDebug("群组消息已收藏，更新创建时间 - user_id: %d, favorite_id: %d",
				userID.(int), favoriteID)
			updatedFavorite, updateErr := ctrl.favoriteRepo.UpdateCreatedAt(favoriteID, userID.(int))
			if updateErr != nil {
				utils.LogError("更新收藏时间失败 (favorite_id: %d): %v", favoriteID, updateErr)
				c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "更新收藏时间失败"})
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"code":    0,
				"message": "已更新收藏时间",
				"data":    updatedFavorite,
			})
			return
		}
	} else {
		// 这是私聊消息，可以正常设置 message_id
		messageIDForFavorite = &req.MessageID
		utils.LogDebug("准备创建收藏（私聊消息）- user_id: %d, message_id: %d, sender_name: %s, message_type: %s",
			userID.(int), req.MessageID, senderName, messageType)

		// 检查私聊消息是否已收藏
		exists, favoriteID, checkErr := ctrl.favoriteRepo.CheckExists(userID.(int), req.MessageID)
		if checkErr != nil {
			utils.LogError("检查收藏状态失败 (user_id: %d, message_id: %d): %v", userID.(int), req.MessageID, checkErr)
			c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "检查收藏状态失败"})
			return
		}

		if exists {
			// 如果已收藏，更新创建时间，让它在列表中排到最前面
			utils.LogDebug("消息已收藏，更新创建时间 - user_id: %d, message_id: %d, favorite_id: %d",
				userID.(int), req.MessageID, favoriteID)
			updatedFavorite, updateErr := ctrl.favoriteRepo.UpdateCreatedAt(favoriteID, userID.(int))
			if updateErr != nil {
				utils.LogError("更新收藏时间失败 (favorite_id: %d): %v", favoriteID, updateErr)
				c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "更新收藏时间失败"})
				return
			}
			c.JSON(http.StatusOK, gin.H{
				"code":    0,
				"message": "已更新收藏时间",
				"data":    updatedFavorite,
			})
			return
		}
	}

	// 创建收藏
	favorite, err := ctrl.favoriteRepo.Create(
		userID.(int),
		messageIDForFavorite,
		message.Content,
		message.MessageType,
		message.FileName,
		message.SenderID,
		message.SenderName,
	)

	if err != nil {
		utils.LogError("创建收藏失败 (user_id: %d, message_id: %d): %v", userID.(int), req.MessageID, err)
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": fmt.Sprintf("收藏失败: %v", err)})
		return
	}

	utils.LogDebug("收藏创建成功 - favorite_id: %d, user_id: %d, message_id: %v",
		favorite.ID, userID.(int), messageIDForFavorite)

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "已保存到收藏夹",
		"data":    favorite,
	})
}

// GetFavorites 获取收藏列表（分页）
// GET /api/favorites?page=1&page_size=20
func (ctrl *FavoriteController) GetFavorites(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 401, "message": "未授权"})
		return
	}

	// 获取分页参数
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))

	// 参数验证
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	// 查询收藏列表
	favorites, total, err := ctrl.favoriteRepo.GetByUserID(userID.(int), page, pageSize)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "获取收藏列表失败"})
		return
	}

	// 计算总页数
	totalPages := (total + pageSize - 1) / pageSize

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "获取成功",
		"data": gin.H{
			"favorites":   favorites,
			"total":       total,
			"page":        page,
			"page_size":   pageSize,
			"total_pages": totalPages,
		},
	})
}

// DeleteFavorite 删除收藏
// DELETE /api/favorites/:id
func (ctrl *FavoriteController) DeleteFavorite(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 401, "message": "未授权"})
		return
	}

	favoriteID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "无效的收藏ID"})
		return
	}

	err = ctrl.favoriteRepo.Delete(favoriteID, userID.(int))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "删除收藏失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "删除成功",
	})
}

// CreateBatchFavorite 批量创建收藏（合并多个消息为一条收藏）
// POST /api/favorites/batch
func (ctrl *FavoriteController) CreateBatchFavorite(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 401, "message": "未授权"})
		return
	}

	var req struct {
		MessageIDs []int `json:"message_ids" binding:"required,min=1"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误"})
		return
	}

	// 获取所有消息详情（支持私聊和群组消息）
	var messages []models.Message
	placeholders := make([]string, len(req.MessageIDs))
	args := make([]interface{}, len(req.MessageIDs))
	for i, id := range req.MessageIDs {
		placeholders[i] = fmt.Sprintf("$%d", i+1)
		args[i] = id
	}

	// 1. 先查询私聊消息表 (messages)
	query := fmt.Sprintf(`SELECT id, sender_id, receiver_id, sender_name, receiver_name, content, message_type, file_name, created_at
		FROM messages WHERE id IN (%s) ORDER BY created_at ASC`, strings.Join(placeholders, ","))

	rows, err := db.DB.Query(query, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "查询私聊消息失败"})
		return
	}

	for rows.Next() {
		var msg models.Message
		err := rows.Scan(
			&msg.ID,
			&msg.SenderID,
			&msg.ReceiverID,
			&msg.SenderName,
			&msg.ReceiverName,
			&msg.Content,
			&msg.MessageType,
			&msg.FileName,
			&msg.CreatedAt,
		)
		if err != nil {
			continue
		}
		messages = append(messages, msg)
	}
	rows.Close()

	// 2. 再查询群组消息表 (group_messages)
	groupQuery := fmt.Sprintf(`SELECT id, sender_id, 0 as receiver_id, sender_name, '' as receiver_name, content, message_type, file_name, created_at
		FROM group_messages WHERE id IN (%s) ORDER BY created_at ASC`, strings.Join(placeholders, ","))

	groupRows, err := db.DB.Query(groupQuery, args...)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "查询群组消息失败"})
		return
	}
	defer groupRows.Close()

	for groupRows.Next() {
		var msg models.Message
		err := groupRows.Scan(
			&msg.ID,
			&msg.SenderID,
			&msg.ReceiverID,
			&msg.SenderName,
			&msg.ReceiverName,
			&msg.Content,
			&msg.MessageType,
			&msg.FileName,
			&msg.CreatedAt,
		)
		if err != nil {
			continue
		}
		messages = append(messages, msg)
	}

	if len(messages) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "未找到有效的消息"})
		return
	}

	// 按时间顺序重新排序（因为可能混合了私聊和群组消息）
	sort.Slice(messages, func(i, j int) bool {
		return messages[i].CreatedAt.Before(messages[j].CreatedAt)
	})

	// 合并消息内容
	var mergedContent strings.Builder
	var senderNames []string
	senderMap := make(map[string]bool)

	mergedContent.WriteString(fmt.Sprintf("【聊天记录】（共%d条）\n", len(messages)))
	mergedContent.WriteString("────────────────────\n")

	for i, msg := range messages {
		// 收集发送者名称（去重）
		if !senderMap[msg.SenderName] {
			senderMap[msg.SenderName] = true
			senderNames = append(senderNames, msg.SenderName)
		}

		// 格式化时间
		timeStr := msg.CreatedAt.Format("15:04:05")

		// 根据消息类型构建内容
		var contentText string
		switch msg.MessageType {
		case "text", "quoted":
			contentText = msg.Content
		case "image":
			contentText = "[图片]"
		case "file":
			if msg.FileName != nil && *msg.FileName != "" {
				contentText = fmt.Sprintf("[文件: %s]", *msg.FileName)
			} else {
				contentText = "[文件]"
			}
		default:
			contentText = fmt.Sprintf("[%s消息]", msg.MessageType)
		}

		mergedContent.WriteString(fmt.Sprintf("%s %s:\n%s\n", timeStr, msg.SenderName, contentText))

		// 不是最后一条消息时添加分隔符
		if i < len(messages)-1 {
			mergedContent.WriteString("\n")
		}
	}

	// 生成收藏的发送者名称（显示所有参与者）
	var displaySenderName string
	if len(senderNames) <= 3 {
		displaySenderName = strings.Join(senderNames, "、")
	} else {
		displaySenderName = fmt.Sprintf("%s等%d人", strings.Join(senderNames[:3], "、"), len(senderNames))
	}

	// 创建收藏记录，message_id 设置为 null（因为是合并的多条消息）
	favorite, err := ctrl.favoriteRepo.Create(
		userID.(int),
		nil, // message_id 为 null，表示这是合并的消息
		mergedContent.String(),
		"merged", // 使用特殊的消息类型表示这是合并的收藏
		nil,
		messages[0].SenderID, // 使用第一条消息的发送者ID
		displaySenderName,    // 显示所有参与者名称
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "收藏失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": fmt.Sprintf("已将%d条消息合并保存到收藏夹", len(messages)),
		"data":    favorite,
	})
}
