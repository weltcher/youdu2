package models

import (
	"database/sql"
	"time"
)

// Favorite 收藏模型
type Favorite struct {
	ID          int       `json:"id" db:"id"`
	UserID      int       `json:"user_id" db:"user_id"`
	MessageID   *int      `json:"message_id,omitempty" db:"message_id"`
	Content     string    `json:"content" db:"content"`
	MessageType string    `json:"message_type" db:"message_type"`
	FileName    *string   `json:"file_name,omitempty" db:"file_name"`
	SenderID    int       `json:"sender_id" db:"sender_id"`
	SenderName  string    `json:"sender_name" db:"sender_name"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

// FavoriteRepository 收藏仓库
type FavoriteRepository struct {
	DB *sql.DB
}

// NewFavoriteRepository 创建收藏仓库实例
func NewFavoriteRepository(db *sql.DB) *FavoriteRepository {
	return &FavoriteRepository{DB: db}
}

// Create 创建收藏
func (r *FavoriteRepository) Create(userID int, messageID *int, content, messageType string, fileName *string, senderID int, senderName string) (*Favorite, error) {
	query := `
		INSERT INTO favorites (user_id, message_id, content, message_type, file_name, sender_id, sender_name, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, CURRENT_TIMESTAMP)
		RETURNING id, user_id, message_id, content, message_type, file_name, sender_id, sender_name, created_at
	`

	var favorite Favorite
	err := r.DB.QueryRow(
		query,
		userID,
		messageID,
		content,
		messageType,
		fileName,
		senderID,
		senderName,
	).Scan(
		&favorite.ID,
		&favorite.UserID,
		&favorite.MessageID,
		&favorite.Content,
		&favorite.MessageType,
		&favorite.FileName,
		&favorite.SenderID,
		&favorite.SenderName,
		&favorite.CreatedAt,
	)

	if err != nil {
		return nil, err
	}

	return &favorite, nil
}

// GetByUserID 获取用户的收藏列表（支持分页）
func (r *FavoriteRepository) GetByUserID(userID, page, pageSize int) ([]Favorite, int, error) {
	// 计算偏移量
	offset := (page - 1) * pageSize

	// 查询总数
	var total int
	countQuery := `SELECT COUNT(*) FROM favorites WHERE user_id = $1`
	err := r.DB.QueryRow(countQuery, userID).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	// 查询分页数据
	query := `
		SELECT id, user_id, message_id, content, message_type, file_name, sender_id, sender_name, created_at
		FROM favorites
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`

	rows, err := r.DB.Query(query, userID, pageSize, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var favorites []Favorite
	for rows.Next() {
		var favorite Favorite
		err := rows.Scan(
			&favorite.ID,
			&favorite.UserID,
			&favorite.MessageID,
			&favorite.Content,
			&favorite.MessageType,
			&favorite.FileName,
			&favorite.SenderID,
			&favorite.SenderName,
			&favorite.CreatedAt,
		)
		if err != nil {
			return nil, 0, err
		}
		favorites = append(favorites, favorite)
	}

	if err = rows.Err(); err != nil {
		return nil, 0, err
	}

	return favorites, total, nil
}

// Delete 删除收藏
func (r *FavoriteRepository) Delete(id, userID int) error {
	query := `DELETE FROM favorites WHERE id = $1 AND user_id = $2`
	result, err := r.DB.Exec(query, id, userID)
	if err != nil {
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return err
	}

	if rowsAffected == 0 {
		return sql.ErrNoRows
	}

	return nil
}

// CheckExists 检查消息是否已被收藏，返回收藏ID（如果存在）
func (r *FavoriteRepository) CheckExists(userID int, messageID int) (bool, int, error) {
	query := `SELECT id FROM favorites WHERE user_id = $1 AND message_id = $2`
	var favoriteID int
	err := r.DB.QueryRow(query, userID, messageID).Scan(&favoriteID)
	if err == sql.ErrNoRows {
		return false, 0, nil
	}
	if err != nil {
		return false, 0, err
	}
	return true, favoriteID, nil
}

// CheckExistsByContent 检查群组消息是否已被收藏（通过内容、发送者ID和用户ID），返回收藏ID（如果存在）
func (r *FavoriteRepository) CheckExistsByContent(userID int, content string, senderID int) (bool, int, error) {
	query := `SELECT id FROM favorites WHERE user_id = $1 AND message_id IS NULL AND content = $2 AND sender_id = $3`
	var favoriteID int
	err := r.DB.QueryRow(query, userID, content, senderID).Scan(&favoriteID)
	if err == sql.ErrNoRows {
		return false, 0, nil
	}
	if err != nil {
		return false, 0, err
	}
	return true, favoriteID, nil
}

// UpdateCreatedAt 更新收藏的创建时间
func (r *FavoriteRepository) UpdateCreatedAt(favoriteID int, userID int) (*Favorite, error) {
	query := `
		UPDATE favorites 
		SET created_at = CURRENT_TIMESTAMP 
		WHERE id = $1 AND user_id = $2
		RETURNING id, user_id, message_id, content, message_type, file_name, sender_id, sender_name, created_at
	`

	var favorite Favorite
	err := r.DB.QueryRow(query, favoriteID, userID).Scan(
		&favorite.ID,
		&favorite.UserID,
		&favorite.MessageID,
		&favorite.Content,
		&favorite.MessageType,
		&favorite.FileName,
		&favorite.SenderID,
		&favorite.SenderName,
		&favorite.CreatedAt,
	)

	if err != nil {
		return nil, err
	}

	return &favorite, nil
}
