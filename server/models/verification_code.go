package models

import (
	"database/sql"
	"time"
)

// VerificationCode 验证码模型
type VerificationCode struct {
	ID        int       `json:"id"`
	Account   string    `json:"account"`
	Code      string    `json:"code"`
	Type      string    `json:"type"` // login, register, reset
	ExpiresAt time.Time `json:"expires_at"`
	CreatedAt time.Time `json:"created_at"`
}

// SendCodeRequest 发送验证码请求
type SendCodeRequest struct {
	Account string `json:"account" binding:"required"`
	Type    string `json:"type" binding:"required,oneof=login register reset"`
}

// VerificationCodeRepository 验证码数据仓库
type VerificationCodeRepository struct {
	DB *sql.DB
}

// NewVerificationCodeRepository 创建验证码仓库
func NewVerificationCodeRepository(db *sql.DB) *VerificationCodeRepository {
	return &VerificationCodeRepository{DB: db}
}

// Create 创建验证码
func (r *VerificationCodeRepository) Create(account, code, codeType string, expiresAt time.Time) error {
	query := `
		INSERT INTO verification_codes (account, code, type, expires_at)
		VALUES ($1, $2, $3, $4)
	`

	_, err := r.DB.Exec(query, account, code, codeType, expiresAt)
	return err
}

// FindLatestValid 查找最新有效的验证码
func (r *VerificationCodeRepository) FindLatestValid(account, codeType string) (*VerificationCode, error) {
	query := `
		SELECT id, account, code, type, expires_at, created_at
		FROM verification_codes
		WHERE account = $1 AND type = $2 AND expires_at > NOW()
		ORDER BY created_at DESC
		LIMIT 1
	`

	vc := &VerificationCode{}
	err := r.DB.QueryRow(query, account, codeType).Scan(
		&vc.ID,
		&vc.Account,
		&vc.Code,
		&vc.Type,
		&vc.ExpiresAt,
		&vc.CreatedAt,
	)

	if err != nil {
		return nil, err
	}

	return vc, nil
}

// Verify 验证验证码
func (r *VerificationCodeRepository) Verify(account, code, codeType string) (bool, error) {
	query := `
		SELECT COUNT(*)
		FROM verification_codes
		WHERE account = $1 AND code = $2 AND type = $3 AND expires_at > NOW()
	`

	var count int
	err := r.DB.QueryRow(query, account, code, codeType).Scan(&count)
	if err != nil {
		return false, err
	}

	return count > 0, nil
}

// DeleteByAccount 删除账号的所有验证码
func (r *VerificationCodeRepository) DeleteByAccount(account, codeType string) error {
	query := `
		DELETE FROM verification_codes
		WHERE account = $1 AND type = $2
	`

	_, err := r.DB.Exec(query, account, codeType)
	return err
}

// CleanExpired 清理过期验证码
func (r *VerificationCodeRepository) CleanExpired() error {
	query := `
		DELETE FROM verification_codes
		WHERE expires_at < NOW()
	`

	_, err := r.DB.Exec(query)
	return err
}

