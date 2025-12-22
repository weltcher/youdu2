package models

import (
	"database/sql"
	"time"
)

// UserRelation 用户联系人关系模型
type UserRelation struct {
	ID              int       `json:"id"`
	UserID          int       `json:"user_id"`
	FriendID        int       `json:"friend_id"`
	ApprovalStatus  string    `json:"approval_status"`    // pending, approved, rejected
	IsBlocked       bool      `json:"is_blocked"`         // 是否被拉黑
	BlockedByUserID *int      `json:"blocked_by_user_id"` // 拉黑操作人ID
	IsDeleted       bool      `json:"is_deleted"`         // 是否被删除（软删除）
	DeletedByUserID *int      `json:"deleted_by_user_id"` // 删除操作人ID
	CreatedAt       time.Time `json:"created_at"`
}

// ContactInfo 联系人信息（包含好友的详细信息）
type ContactInfo struct {
	RelationID      int       `json:"relation_id"`
	UserID          int       `json:"user_id"` // 发起方的用户ID
	FriendID        int       `json:"friend_id"`
	Username        string    `json:"username"`
	FullName        *string   `json:"full_name"`
	Avatar          string    `json:"avatar"`
	WorkSignature   *string   `json:"work_signature"`
	Status          string    `json:"status"`
	Email           *string   `json:"email"`
	Department      *string   `json:"department"`
	Position        *string   `json:"position"`
	ApprovalStatus  string    `json:"approval_status"`    // pending, approved, rejected
	IsBlocked       bool      `json:"is_blocked"`         // 是否被拉黑（关系是否被拉黑）
	BlockedByUserID *int      `json:"blocked_by_user_id"` // 拉黑操作人ID
	IsBlockedByMe   bool      `json:"is_blocked_by_me"`   // 当前用户是否拉黑了对方
	IsDeleted       bool      `json:"is_deleted"`         // 是否被删除（软删除）
	DeletedByUserID *int      `json:"deleted_by_user_id"` // 删除操作人ID
	CreatedAt       time.Time `json:"created_at"`
}

// AddContactRequest 添加联系人请求
type AddContactRequest struct {
	FriendUsername string `json:"friend_username" binding:"required"`
}

// ContactRepository 联系人数据仓库
type ContactRepository struct {
	DB *sql.DB
}

// NewContactRepository 创建联系人仓库
func NewContactRepository(db *sql.DB) *ContactRepository {
	return &ContactRepository{DB: db}
}

// CheckRelationExists 检查联系人关系是否已存在（双向检查）
// 检查 (user_id = A AND friend_id = B) 或 (user_id = B AND friend_id = A)
func (r *ContactRepository) CheckRelationExists(userID, friendID int) (bool, error) {
	query := `
		SELECT EXISTS(
			SELECT 1 FROM user_relations 
			WHERE (user_id = $1 AND friend_id = $2) 
			   OR (user_id = $2 AND friend_id = $1)
		)
	`

	var exists bool
	err := r.DB.QueryRow(query, userID, friendID).Scan(&exists)
	if err != nil {
		return false, err
	}

	return exists, nil
}

// GetRelationByUsers 获取两个用户之间的关系详情
func (r *ContactRepository) GetRelationByUsers(userID, friendID int) (*UserRelation, error) {
	query := `
		SELECT id, user_id, friend_id, approval_status, COALESCE(is_deleted, false), created_at
		FROM user_relations
		WHERE (user_id = $1 AND friend_id = $2)
		   OR (user_id = $2 AND friend_id = $1)
		LIMIT 1
	`

	relation := &UserRelation{}
	err := r.DB.QueryRow(query, userID, friendID).Scan(
		&relation.ID,
		&relation.UserID,
		&relation.FriendID,
		&relation.ApprovalStatus,
		&relation.IsDeleted,
		&relation.CreatedAt,
	)

	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	return relation, nil
}

// UpdateRelationStatus 更新联系人关系状态
func (r *ContactRepository) UpdateRelationStatus(relationID int, status string) error {
	query := `
		UPDATE user_relations
		SET approval_status = $2, created_at = CURRENT_TIMESTAMP
		WHERE id = $1
	`

	_, err := r.DB.Exec(query, relationID, status)
	return err
}

// AddContact 添加联系人
func (r *ContactRepository) AddContact(userID, friendID int) (*UserRelation, error) {
	query := `
		INSERT INTO user_relations (user_id, friend_id, approval_status)
		VALUES ($1, $2, 'pending')
		RETURNING id, user_id, friend_id, approval_status, created_at
	`

	relation := &UserRelation{}
	err := r.DB.QueryRow(query, userID, friendID).Scan(
		&relation.ID,
		&relation.UserID,
		&relation.FriendID,
		&relation.ApprovalStatus,
		&relation.CreatedAt,
	)

	if err != nil {
		return nil, err
	}

	return relation, nil
}

// GetContactsByUserID 获取用户的所有联系人（包含详细信息）
// 返回任意一方approved的联系人关系，且未被删除的联系人
func (r *ContactRepository) GetContactsByUserID(userID int) ([]ContactInfo, error) {
	query := `
		SELECT DISTINCT
			CASE 
				WHEN ur1.user_id = $1 THEN ur1.id
				ELSE ur2.id
			END as relation_id,
			$1 as user_id,
			u.id as friend_id,
			u.username,
			u.full_name,
			u.avatar,
			u.work_signature,
			u.status,
			u.email,
			u.department,
			u.position,
			CASE 
				WHEN ur1.user_id = $1 THEN ur1.approval_status
				ELSE ur2.approval_status
			END as approval_status,
			-- is_blocked: 关系是否被拉黑（任意一方拉黑都算）
			(COALESCE(ur1.is_blocked, false) OR COALESCE(ur2.is_blocked, false)) as is_blocked,
			-- blocked_by_user_id: 拉黑操作人ID
			CASE 
				WHEN ur1.is_blocked = true THEN ur1.blocked_by_user_id
				WHEN ur2.is_blocked = true THEN ur2.blocked_by_user_id
				ELSE NULL
			END as blocked_by_user_id,
			-- is_blocked_by_me: 当前用户是否拉黑了对方
			CASE 
				WHEN ur1.user_id = $1 THEN COALESCE(ur1.is_blocked, false)
				ELSE COALESCE(ur2.is_blocked, false)
			END as is_blocked_by_me,
			-- is_deleted: 关系是否被删除（任意一方删除都算）
			(COALESCE(ur1.is_deleted, false) OR COALESCE(ur2.is_deleted, false)) as is_deleted,
			-- deleted_by_user_id: 删除操作人ID
			CASE 
				WHEN ur1.is_deleted = true THEN ur1.deleted_by_user_id
				WHEN ur2.is_deleted = true THEN ur2.deleted_by_user_id
				ELSE NULL
			END as deleted_by_user_id,
			CASE 
				WHEN ur1.user_id = $1 THEN ur1.created_at
				ELSE ur2.created_at
			END as created_at
		FROM users u
		LEFT JOIN user_relations ur1 ON ur1.user_id = $1 AND ur1.friend_id = u.id
		LEFT JOIN user_relations ur2 ON ur2.user_id = u.id AND ur2.friend_id = $1
		WHERE (
			(ur1.approval_status = 'approved' AND COALESCE(ur1.is_deleted, false) = false)
			OR 
			(ur2.approval_status = 'approved' AND COALESCE(ur2.is_deleted, false) = false)
		)
		AND u.id != $1
		ORDER BY 
			CASE 
				WHEN ur1.user_id = $1 THEN ur1.created_at
				ELSE ur2.created_at
			END DESC
	`

	rows, err := r.DB.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var contacts []ContactInfo
	for rows.Next() {
		var contact ContactInfo
		err := rows.Scan(
			&contact.RelationID,
			&contact.UserID,
			&contact.FriendID,
			&contact.Username,
			&contact.FullName,
			&contact.Avatar,
			&contact.WorkSignature,
			&contact.Status,
			&contact.Email,
			&contact.Department,
			&contact.Position,
			&contact.ApprovalStatus,
			&contact.IsBlocked,
			&contact.BlockedByUserID,
			&contact.IsBlockedByMe,
			&contact.IsDeleted,
			&contact.DeletedByUserID,
			&contact.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		contacts = append(contacts, contact)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return contacts, nil
}

// GetPendingContactRequests 获取待审核的联系人申请
// 只返回别人发给当前用户的、状态为pending且未被删除的申请
func (r *ContactRepository) GetPendingContactRequests(userID int) ([]ContactInfo, error) {
	query := `
		SELECT 
			ur.id as relation_id,
			ur.user_id as user_id,
			ur.friend_id as friend_id,
			u.username,
			u.full_name,
			u.avatar,
			u.work_signature,
			u.status,
			u.email,
			u.department,
			u.position,
			ur.approval_status,
			ur.is_blocked,
			false as is_blocked_by_me,
			ur.is_deleted,
			ur.created_at
		FROM user_relations ur
		JOIN users u ON ur.user_id = u.id
		WHERE ur.friend_id = $1
		  AND ur.approval_status = 'pending'
		  AND ur.is_deleted = false
		ORDER BY ur.created_at DESC
	`

	rows, err := r.DB.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var requests []ContactInfo
	for rows.Next() {
		var request ContactInfo
		err := rows.Scan(
			&request.RelationID,
			&request.UserID,
			&request.FriendID,
			&request.Username,
			&request.FullName,
			&request.Avatar,
			&request.WorkSignature,
			&request.Status,
			&request.Email,
			&request.Department,
			&request.Position,
			&request.ApprovalStatus,
			&request.IsBlocked,
			&request.IsBlockedByMe,
			&request.IsDeleted,
			&request.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		requests = append(requests, request)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return requests, nil
}

// DeleteContact 删除联系人
func (r *ContactRepository) DeleteContact(userID, friendID int) error {
	query := `
		DELETE FROM user_relations
		WHERE user_id = $1 AND friend_id = $2
	`

	result, err := r.DB.Exec(query, userID, friendID)
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

// SearchContactResult 搜索联系人结果
type SearchContactResult struct {
	UserID          int    `json:"user_id"`
	Username        string `json:"username"`
	FullName        string `json:"full_name"`
	Avatar          string `json:"avatar"`
	Status          string `json:"status"`
	LastMessageTime string `json:"last_message_time"`
	LastMessage     string `json:"last_message"`
}

// SearchContacts 根据关键字搜索联系人
func (r *ContactRepository) SearchContacts(userID int, keyword string) ([]SearchContactResult, error) {
	query := `
		WITH user_contacts AS (
			-- 获取用户的所有已通过审核的联系人（双向关系）
			SELECT DISTINCT
				CASE 
					WHEN user_id = $1 THEN friend_id
					ELSE user_id
				END as contact_id
			FROM user_relations
			WHERE (user_id = $1 OR friend_id = $1) AND approval_status = 'approved'
		),
		last_messages AS (
			-- 获取每个联系人的最后一条消息
			SELECT 
				CASE 
					WHEN sender_id = $1 THEN receiver_id
					ELSE sender_id
				END as contact_id,
				MAX(created_at) as last_time
			FROM messages
			WHERE sender_id = $1 OR receiver_id = $1
			GROUP BY contact_id
		)
		SELECT 
			u.id as user_id,
			u.username,
			COALESCE(u.full_name, '') as full_name,
			COALESCE(u.avatar, '') as avatar,
			COALESCE(u.status, 'offline') as status,
			COALESCE(lm.last_time, u.created_at) as last_message_time,
			COALESCE(m.content, '') as last_message
		FROM user_contacts uc
		JOIN users u ON u.id = uc.contact_id
		LEFT JOIN last_messages lm ON lm.contact_id = uc.contact_id
		LEFT JOIN messages m ON (
			(m.sender_id = uc.contact_id AND m.receiver_id = $1) OR
			(m.sender_id = $1 AND m.receiver_id = uc.contact_id)
		) AND m.created_at = lm.last_time
		WHERE u.username ILIKE $2 OR COALESCE(u.full_name, '') ILIKE $2
		ORDER BY COALESCE(lm.last_time, u.created_at) DESC
	`

	// 添加通配符进行模糊搜索
	searchPattern := "%" + keyword + "%"

	rows, err := r.DB.Query(query, userID, searchPattern)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []SearchContactResult
	for rows.Next() {
		var result SearchContactResult
		var lastMessageTime time.Time

		err := rows.Scan(
			&result.UserID,
			&result.Username,
			&result.FullName,
			&result.Avatar,
			&result.Status,
			&lastMessageTime,
			&result.LastMessage,
		)
		if err != nil {
			return nil, err
		}

		// 格式化时间
		result.LastMessageTime = formatMessageTime(lastMessageTime)
		results = append(results, result)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return results, nil
}

// formatMessageTime 格式化消息时间
func formatMessageTime(t time.Time) string {
	now := time.Now()

	// 判断是否是今天
	if t.Year() == now.Year() && t.YearDay() == now.YearDay() {
		return "今天"
	}

	// 判断是否是昨天
	yesterday := now.AddDate(0, 0, -1)
	if t.Year() == yesterday.Year() && t.YearDay() == yesterday.YearDay() {
		return "昨天"
	}

	// 其他日期，返回月-日格式
	return t.Format("01-02")
}

// GetUserContacts 获取用户主动添加的所有联系人
func (r *ContactRepository) GetUserContacts(userID int) ([]UserRelation, error) {
	query := `
		SELECT id, user_id, friend_id, created_at
		FROM user_relations
		WHERE user_id = $1
		ORDER BY created_at DESC
	`

	rows, err := r.DB.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var contacts []UserRelation
	for rows.Next() {
		var contact UserRelation
		err := rows.Scan(
			&contact.ID,
			&contact.UserID,
			&contact.FriendID,
			&contact.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		contacts = append(contacts, contact)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return contacts, nil
}

// GetUsersWhoAddedContact 获取所有添加了该用户为联系人的用户（反向关系）
func (r *ContactRepository) GetUsersWhoAddedContact(userID int) ([]UserRelation, error) {
	query := `
		SELECT id, user_id, friend_id, created_at
		FROM user_relations
		WHERE friend_id = $1
		ORDER BY created_at DESC
	`

	rows, err := r.DB.Query(query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var contacts []UserRelation
	for rows.Next() {
		var contact UserRelation
		err := rows.Scan(
			&contact.ID,
			&contact.UserID,
			&contact.FriendID,
			&contact.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		contacts = append(contacts, contact)
	}

	if err = rows.Err(); err != nil {
		return nil, err
	}

	return contacts, nil
}

// GetRelationByID 根据关系ID获取联系人关系信息
func (r *ContactRepository) GetRelationByID(relationID int) (*UserRelation, error) {
	query := `
		SELECT id, user_id, friend_id, approval_status, created_at
		FROM user_relations
		WHERE id = $1
	`

	relation := &UserRelation{}
	err := r.DB.QueryRow(query, relationID).Scan(
		&relation.ID,
		&relation.UserID,
		&relation.FriendID,
		&relation.ApprovalStatus,
		&relation.CreatedAt,
	)

	if err != nil {
		return nil, err
	}

	return relation, nil
}

// UpdateApprovalStatus 更新联系人审核状态
func (r *ContactRepository) UpdateApprovalStatus(relationID int, approvalStatus string) error {
	query := `
		UPDATE user_relations
		SET approval_status = $1
		WHERE id = $2
	`

	result, err := r.DB.Exec(query, approvalStatus, relationID)
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

// BlockContact 拉黑联系人
// 只能拉黑已存在的好友关系，不能对陌生人进行拉黑操作
func (r *ContactRepository) BlockContact(userID, friendID int) error {
	// 检查是否存在好友关系（双向检查）
	checkQuery := `
		SELECT COUNT(*) FROM user_relations
		WHERE ((user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1))
		AND approval_status = 'approved'
	`

	var count int
	err := r.DB.QueryRow(checkQuery, userID, friendID).Scan(&count)
	if err != nil {
		return err
	}

	// 如果没有好友关系，不能拉黑
	if count == 0 {
		return sql.ErrNoRows // 或者返回自定义错误：errors.New("不能拉黑非好友用户")
	}

	// 更新拉黑状态（双向查找，只更新找到的那条记录）
	updateQuery := `
		UPDATE user_relations
		SET is_blocked = true, blocked_by_user_id = $3
		WHERE ((user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1))
		AND approval_status = 'approved'
	`

	result, err := r.DB.Exec(updateQuery, userID, friendID, userID)
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

// UnblockContact 恢复联系人（取消拉黑）
// 只更新当前用户拉黑对方的关系（双向查找，与BlockContact保持一致）
func (r *ContactRepository) UnblockContact(userID, friendID int) error {
	query := `
		UPDATE user_relations
		SET is_blocked = false, blocked_by_user_id = NULL
		WHERE ((user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1))
		AND blocked_by_user_id = $1
	`

	result, err := r.DB.Exec(query, userID, friendID)
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

// DeleteContactById 硬删除联系人（通过friendID）
// 删除双向的好友关系记录
func (r *ContactRepository) DeleteContactById(userID, friendID int) error {
	// 硬删除双向关系记录
	query := `
		DELETE FROM user_relations
		WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1)
	`

	result, err := r.DB.Exec(query, userID, friendID)
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

// DeleteRelation 删除指定的联系人关系记录（通过relationID）
// 硬删除单条关系记录
func (r *ContactRepository) DeleteRelation(relationID int) error {
	query := `
		DELETE FROM user_relations
		WHERE id = $1
	`

	result, err := r.DB.Exec(query, relationID)
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

// RestoreDeletedRelation 恢复已删除的联系人关系
// 将软删除的关系恢复，并重置为pending状态
func (r *ContactRepository) RestoreDeletedRelation(relationID int) error {
	query := `
		UPDATE user_relations
		SET is_deleted = false, approval_status = 'pending', created_at = CURRENT_TIMESTAMP
		WHERE id = $1
	`

	_, err := r.DB.Exec(query, relationID)
	return err
}

// CheckContactBlocked 检查联系人是否被拉黑
// 检查接收者是否拉黑了发送者（从接收者的角度检查）
// userID: 接收者ID, friendID: 发送者ID
// 需要检查接收者（userID）是否拉黑了发送者（friendID）
// 即检查 user_id = userID（接收者） AND friend_id = friendID（发送者）的关系是否被拉黑
func (r *ContactRepository) CheckContactBlocked(userID, friendID int) (bool, error) {
	// ⚡ 关键修复：由于user_relations表中一条记录代表双向好友关系
	// 需要检查双向关系：(user_id=A AND friend_id=B) OR (user_id=B AND friend_id=A)
	query := `
		SELECT COALESCE(is_blocked, false)
		FROM user_relations
		WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1)
		LIMIT 1
	`

	var isBlocked bool
	err := r.DB.QueryRow(query, userID, friendID).Scan(&isBlocked)
	if err != nil {
		if err == sql.ErrNoRows {
			// 如果双向都没有关系记录，返回未拉黑
			return false, nil
		}
		return false, err
	}

	return isBlocked, nil
}

// CheckContactDeleted 检查联系人是否被删除
// 检查接收者是否删除了发送者（从接收者的角度检查）
// userID: 接收者ID, friendID: 发送者ID
// 需要检查接收者（userID）是否删除了发送者（friendID）
// 即检查 user_id = userID（接收者） AND friend_id = friendID（发送者）的关系是否被删除
func (r *ContactRepository) CheckContactDeleted(userID, friendID int) (bool, error) {
	// ⚡ 关键修复：由于user_relations表中一条记录代表双向好友关系
	// 需要检查双向关系：(user_id=A AND friend_id=B) OR (user_id=B AND friend_id=A)
	query := `
		SELECT COALESCE(is_deleted, false)
		FROM user_relations
		WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1)
		LIMIT 1
	`

	var isDeleted bool
	err := r.DB.QueryRow(query, userID, friendID).Scan(&isDeleted)
	if err != nil {
		if err == sql.ErrNoRows {
			// 如果双向都没有关系记录，说明从未添加过好友，返回未删除
			return false, nil
		}
		return false, err
	}

	return isDeleted, nil
}

// CheckContactApprovalStatus 检查好友关系的审核状态
// 检查发送者向接收者发起的好友申请状态（从发送者的角度检查）
// senderID: 发送者ID（发起好友申请的人）, receiverID: 接收者ID（审核好友申请的人）
// 返回值: "pending"(待审核), "approved"(已通过), "rejected"(已拒绝), "" (无关系记录)
func (r *ContactRepository) CheckContactApprovalStatus(senderID, receiverID int) (string, error) {
	// ⚡ 关键修复：由于user_relations表中一条记录代表双向好友关系
	// 需要检查双向关系：(user_id=A AND friend_id=B) OR (user_id=B AND friend_id=A)
	query := `
		SELECT COALESCE(approval_status, 'approved')
		FROM user_relations
		WHERE (user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1)
		LIMIT 1
	`

	var approvalStatus string
	err := r.DB.QueryRow(query, senderID, receiverID).Scan(&approvalStatus)
	if err != nil {
		if err == sql.ErrNoRows {
			// 如果双向都没有关系记录，返回空字符串
			return "", nil
		}
		return "", err
	}

	return approvalStatus, nil
}
