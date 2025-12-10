package controllers

import (
	"database/sql"
	"fmt"
	"strconv"
	"youdu-server/db"
	"youdu-server/models"
	"youdu-server/utils"

	"github.com/gin-gonic/gin"
)

// FileAssistantController 文件传输助手控制器
type FileAssistantController struct{}

// NewFileAssistantController 创建文件传输助手控制器
func NewFileAssistantController() *FileAssistantController {
	return &FileAssistantController{}
}

// CreateMessage 创建文件助手消息
func (fac *FileAssistantController) CreateMessage(c *gin.Context) {
	// 从上下文获取当前用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "未授权")
		return
	}

	// 解析请求
	var req models.CreateFileAssistantMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.BadRequest(c, "请求参数错误: "+err.Error())
		return
	}

	// 默认消息类型为text
	if req.MessageType == "" {
		req.MessageType = "text"
	}

	// 插入消息到数据库
	query := `
		INSERT INTO file_assistant_messages (user_id, content, message_type, file_name, quoted_message_id, quoted_message_content, status, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
		RETURNING id, user_id, content, message_type, file_name, quoted_message_id, quoted_message_content, status, created_at
	`

	var message models.FileAssistantMessage
	var fileName, quotedContent sql.NullString
	var quotedID sql.NullInt64

	err := db.DB.QueryRow(
		query,
		userID,
		req.Content,
		req.MessageType,
		nullString(req.FileName),
		nullInt(req.QuotedMessageID),
		nullString(req.QuotedMessageContent),
		"normal",
	).Scan(
		&message.ID,
		&message.UserID,
		&message.Content,
		&message.MessageType,
		&fileName,
		&quotedID,
		&quotedContent,
		&message.Status,
		&message.CreatedAt,
	)

	if err != nil {
		utils.InternalServerError(c, "创建消息失败: "+err.Error())
		return
	}

	// 处理可空字段
	if fileName.Valid {
		message.FileName = &fileName.String
	}
	if quotedID.Valid {
		id := int(quotedID.Int64)
		message.QuotedMessageID = &id
	}
	if quotedContent.Valid {
		message.QuotedMessageContent = &quotedContent.String
	}

	utils.Success(c, message)
}

// GetMessages 获取文件助手消息列表
func (fac *FileAssistantController) GetMessages(c *gin.Context) {
	// 从上下文获取当前用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "未授权")
		return
	}

	// 获取分页参数
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "50"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 50
	}
	offset := (page - 1) * pageSize

	// 查询消息列表（按时间升序，最新的消息在最下面）
	query := `
		SELECT id, user_id, content, message_type, file_name, quoted_message_id, quoted_message_content, status, created_at
		FROM file_assistant_messages
		WHERE user_id = $1
		ORDER BY created_at ASC
		LIMIT $2 OFFSET $3
	`

	rows, err := db.DB.Query(query, userID, pageSize, offset)
	if err != nil {
		utils.InternalServerError(c, "查询消息失败: "+err.Error())
		return
	}
	defer rows.Close()

	messages := []models.FileAssistantMessage{}
	for rows.Next() {
		var message models.FileAssistantMessage
		var fileName, quotedContent sql.NullString
		var quotedID sql.NullInt64

		err := rows.Scan(
			&message.ID,
			&message.UserID,
			&message.Content,
			&message.MessageType,
			&fileName,
			&quotedID,
			&quotedContent,
			&message.Status,
			&message.CreatedAt,
		)
		if err != nil {
			continue
		}

		// 处理可空字段
		if fileName.Valid {
			message.FileName = &fileName.String
		}
		if quotedID.Valid {
			id := int(quotedID.Int64)
			message.QuotedMessageID = &id
		}
		if quotedContent.Valid {
			message.QuotedMessageContent = &quotedContent.String
		}

		messages = append(messages, message)
	}

	// 查询总数
	var total int
	countQuery := `SELECT COUNT(*) FROM file_assistant_messages WHERE user_id = $1`
	db.DB.QueryRow(countQuery, userID).Scan(&total)

	utils.Success(c, gin.H{
		"messages": messages,
		"total":    total,
		"page":     page,
		"pageSize": pageSize,
	})
}

// DeleteMessage 删除文件助手消息
func (fac *FileAssistantController) DeleteMessage(c *gin.Context) {
	// 从上下文获取当前用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "未授权")
		return
	}

	// 获取消息ID
	messageIDStr := c.Param("id")
	messageID, err := strconv.Atoi(messageIDStr)
	if err != nil {
		utils.BadRequest(c, "无效的消息ID")
		return
	}

	// 删除消息（仅能删除自己的消息）
	query := `DELETE FROM file_assistant_messages WHERE id = $1 AND user_id = $2`
	result, err := db.DB.Exec(query, messageID, userID)
	if err != nil {
		utils.InternalServerError(c, "删除消息失败: "+err.Error())
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		utils.NotFound(c, "消息不存在或无权删除")
		return
	}

	utils.Success(c, gin.H{"message": "删除成功"})
}

// RecallMessage 撤回文件助手消息
func (fac *FileAssistantController) RecallMessage(c *gin.Context) {
	// 从上下文获取当前用户ID
	userID, exists := c.Get("user_id")
	if !exists {
		utils.Unauthorized(c, "未授权")
		return
	}

	// 获取消息ID
	messageIDStr := c.Param("id")
	messageID, err := strconv.Atoi(messageIDStr)
	if err != nil {
		utils.BadRequest(c, "无效的消息ID")
		return
	}

	// 更新消息状态为已撤回
	query := `UPDATE file_assistant_messages SET status = 'recalled' WHERE id = $1 AND user_id = $2`
	result, err := db.DB.Exec(query, messageID, userID)
	if err != nil {
		utils.InternalServerError(c, "撤回消息失败: "+err.Error())
		return
	}

	rowsAffected, _ := result.RowsAffected()
	if rowsAffected == 0 {
		utils.NotFound(c, "消息不存在或无权撤回")
		return
	}

	utils.Success(c, gin.H{"message": "撤回成功"})
}

// 辅助函数：将空字符串转为 sql.NullString
func nullString(s string) sql.NullString {
	if s == "" {
		return sql.NullString{}
	}
	return sql.NullString{String: s, Valid: true}
}

// 辅助函数：将0转为 sql.NullInt64
func nullInt(i int) sql.NullInt64 {
	if i == 0 {
		return sql.NullInt64{}
	}
	return sql.NullInt64{Int64: int64(i), Valid: true}
}

// GetLatestMessage 获取文件助手的最新消息（用于最近联系人列表）
func (fac *FileAssistantController) GetLatestMessage(userID int) (message string, lastTime string, unreadCount int, err error) {
	query := `
		SELECT content, created_at
		FROM file_assistant_messages
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT 1
	`

	var content string
	var createdAt sql.NullTime

	err = db.DB.QueryRow(query, userID).Scan(&content, &createdAt)
	if err != nil {
		if err == sql.ErrNoRows {
			// 没有消息时返回默认值
			return "暂无消息", "", 0, nil
		}
		return "", "", 0, fmt.Errorf("查询最新消息失败: %v", err)
	}

	lastTime = ""
	if createdAt.Valid {
		lastTime = createdAt.Time.Format("2006-01-02 15:04:05")
	}

	// 文件助手没有未读概念，始终为0
	return content, lastTime, 0, nil
}
