package models

import "time"

// FileAssistantMessage 文件传输助手消息模型
type FileAssistantMessage struct {
	ID                   int        `json:"id" db:"id"`
	UserID               int        `json:"user_id" db:"user_id"`
	Content              string     `json:"content" db:"content"`
	MessageType          string     `json:"message_type" db:"message_type"`                               // text, image, file, quoted
	FileName             *string    `json:"file_name,omitempty" db:"file_name"`                           // 文件名（用于file类型）
	QuotedMessageID      *int       `json:"quoted_message_id,omitempty" db:"quoted_message_id"`           // 被引用的消息ID
	QuotedMessageContent *string    `json:"quoted_message_content,omitempty" db:"quoted_message_content"` // 被引用的消息内容
	Status               string     `json:"status" db:"status"`                                           // 消息状态：normal-正常, recalled-已撤回
	CreatedAt            time.Time  `json:"created_at" db:"created_at"`
}

// CreateFileAssistantMessageRequest 创建文件助手消息请求
type CreateFileAssistantMessageRequest struct {
	Content              string `json:"content" binding:"required"`
	MessageType          string `json:"message_type"`
	FileName             string `json:"file_name,omitempty"`
	QuotedMessageID      int    `json:"quoted_message_id,omitempty"`
	QuotedMessageContent string `json:"quoted_message_content,omitempty"`
}

