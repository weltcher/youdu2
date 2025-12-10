package models

import (
	"database/sql"
	"time"
)

// FavoriteContact 常用联系人模型
type FavoriteContact struct {
	ID        int       `json:"id" db:"id"`
	UserID    int       `json:"user_id" db:"user_id"`
	ContactID int       `json:"contact_id" db:"contact_id"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// FavoriteGroup 常用群组模型
type FavoriteGroup struct {
	ID        int       `json:"id" db:"id"`
	UserID    int       `json:"user_id" db:"user_id"`
	GroupID   int       `json:"group_id" db:"group_id"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
}

// FavoriteContactDetail 常用联系人详情（包含用户信息）
type FavoriteContactDetail struct {
	ID            int       `json:"id"`
	ContactID     int       `json:"contact_id"`
	Username      string    `json:"username"`
	FullName      *string   `json:"full_name,omitempty"`
	Avatar        string    `json:"avatar"`
	WorkSignature *string   `json:"work_signature,omitempty"`
	Status        string    `json:"status"`
	Department    *string   `json:"department,omitempty"`
	Position      *string   `json:"position,omitempty"`
	Phone         *string   `json:"phone,omitempty"`
	Email         *string   `json:"email,omitempty"`
	CreatedAt     time.Time `json:"created_at"`
}

// FavoriteGroupDetail 常用群组详情（包含群组信息）
type FavoriteGroupDetail struct {
	ID           int       `json:"id"`
	GroupID      int       `json:"group_id"`
	Name         string    `json:"name"`
	Announcement *string   `json:"announcement,omitempty"`
	Avatar       *string   `json:"avatar,omitempty"`
	OwnerID      int       `json:"owner_id"`
	MemberCount  int       `json:"member_count"`
	CreatedAt    time.Time `json:"created_at"`
}

// AddFavoriteRequest 添加常用联系人/群组请求
type AddFavoriteRequest struct {
	ContactID int `json:"contact_id,omitempty"` // 用于常用联系人
	GroupID   int `json:"group_id,omitempty"`   // 用于常用群组
}

// FavoriteCommonRepository 常用联系人和群组数据仓库
type FavoriteCommonRepository struct {
	DB *sql.DB
}

// NewFavoriteCommonRepository 创建常用联系人和群组仓库
func NewFavoriteCommonRepository(db *sql.DB) *FavoriteCommonRepository {
	return &FavoriteCommonRepository{DB: db}
}

// ===== 常用联系人相关方法 =====

// AddFavoriteContact 添加常用联系人
func (r *FavoriteCommonRepository) AddFavoriteContact(userID, contactID int) error {
	query := `
		INSERT INTO favorite_contacts (user_id, contact_id)
		VALUES ($1, $2)
		ON CONFLICT (user_id, contact_id) DO NOTHING
	`
	_, err := r.DB.Exec(query, userID, contactID)
	return err
}

// RemoveFavoriteContact 移除常用联系人
func (r *FavoriteCommonRepository) RemoveFavoriteContact(userID, contactID int) error {
	query := `
		DELETE FROM favorite_contacts
		WHERE user_id = $1 AND contact_id = $2
	`
	_, err := r.DB.Exec(query, userID, contactID)
	return err
}

// IsFavoriteContact 检查是否为常用联系人
func (r *FavoriteCommonRepository) IsFavoriteContact(userID, contactID int) (bool, error) {
	query := `
		SELECT COUNT(*) > 0
		FROM favorite_contacts
		WHERE user_id = $1 AND contact_id = $2
	`
	var isFavorite bool
	err := r.DB.QueryRow(query, userID, contactID).Scan(&isFavorite)
	return isFavorite, err
}

// GetFavoriteContacts 获取常用联系人列表
func (r *FavoriteCommonRepository) GetFavoriteContacts(userID int) ([]FavoriteContactDetail, error) {
	query := `
		SELECT 
			fc.id,
			fc.contact_id,
			u.username,
			u.full_name,
			u.avatar,
			u.work_signature,
			u.status,
			u.department,
			u.position,
			u.phone,
			u.email,
			fc.created_at
		FROM favorite_contacts fc
		JOIN users u ON fc.contact_id = u.id
		WHERE fc.user_id = $1
		ORDER BY fc.created_at DESC
	`

	rows, err := r.DB.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var contacts []FavoriteContactDetail
	for rows.Next() {
		var contact FavoriteContactDetail
		err := rows.Scan(
			&contact.ID,
			&contact.ContactID,
			&contact.Username,
			&contact.FullName,
			&contact.Avatar,
			&contact.WorkSignature,
			&contact.Status,
			&contact.Department,
			&contact.Position,
			&contact.Phone,
			&contact.Email,
			&contact.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		contacts = append(contacts, contact)
	}

	return contacts, nil
}

// ===== 常用群组相关方法 =====

// AddFavoriteGroup 添加常用群组
func (r *FavoriteCommonRepository) AddFavoriteGroup(userID, groupID int) error {
	query := `
		INSERT INTO favorite_groups (user_id, group_id)
		VALUES ($1, $2)
		ON CONFLICT (user_id, group_id) DO NOTHING
	`
	_, err := r.DB.Exec(query, userID, groupID)
	return err
}

// RemoveFavoriteGroup 移除常用群组
func (r *FavoriteCommonRepository) RemoveFavoriteGroup(userID, groupID int) error {
	query := `
		DELETE FROM favorite_groups
		WHERE user_id = $1 AND group_id = $2
	`
	_, err := r.DB.Exec(query, userID, groupID)
	return err
}

// IsFavoriteGroup 检查是否为常用群组
func (r *FavoriteCommonRepository) IsFavoriteGroup(userID, groupID int) (bool, error) {
	query := `
		SELECT COUNT(*) > 0
		FROM favorite_groups
		WHERE user_id = $1 AND group_id = $2
	`
	var isFavorite bool
	err := r.DB.QueryRow(query, userID, groupID).Scan(&isFavorite)
	return isFavorite, err
}

// GetFavoriteGroups 获取常用群组列表
func (r *FavoriteCommonRepository) GetFavoriteGroups(userID int) ([]FavoriteGroupDetail, error) {
	query := `
		SELECT 
			fg.id,
			fg.group_id,
			g.name,
			g.announcement,
			g.avatar,
			g.owner_id,
			(SELECT COUNT(*) FROM group_members WHERE group_id = g.id) as member_count,
			fg.created_at
		FROM favorite_groups fg
		JOIN groups g ON fg.group_id = g.id
		WHERE fg.user_id = $1
		ORDER BY fg.created_at DESC
	`

	rows, err := r.DB.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var groups []FavoriteGroupDetail
	for rows.Next() {
		var group FavoriteGroupDetail
		err := rows.Scan(
			&group.ID,
			&group.GroupID,
			&group.Name,
			&group.Announcement,
			&group.Avatar,
			&group.OwnerID,
			&group.MemberCount,
			&group.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		groups = append(groups, group)
	}

	return groups, nil
}
