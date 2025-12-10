package models

import (
	"database/sql"
	"time"
)

// ServerSetting 服务器设置模型
type ServerSetting struct {
	ID          int       `json:"id"`
	Key         string    `json:"key"`
	Value       string    `json:"value"`
	Description string    `json:"description"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// ServerSettingRepository 服务器设置数据仓库
type ServerSettingRepository struct {
	DB *sql.DB
}

// NewServerSettingRepository 创建服务器设置仓库
func NewServerSettingRepository(db *sql.DB) *ServerSettingRepository {
	return &ServerSettingRepository{DB: db}
}

// GetAll 获取所有设置
func (r *ServerSettingRepository) GetAll() ([]ServerSetting, error) {
	query := `
		SELECT id, key, value, description, updated_at
		FROM server_settings
		ORDER BY id
	`

	rows, err := r.DB.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var settings []ServerSetting
	for rows.Next() {
		var s ServerSetting
		err := rows.Scan(&s.ID, &s.Key, &s.Value, &s.Description, &s.UpdatedAt)
		if err != nil {
			return nil, err
		}
		settings = append(settings, s)
	}

	return settings, nil
}

// GetByKey 根据键获取设置
func (r *ServerSettingRepository) GetByKey(key string) (*ServerSetting, error) {
	query := `
		SELECT id, key, value, description, updated_at
		FROM server_settings
		WHERE key = $1
	`

	s := &ServerSetting{}
	err := r.DB.QueryRow(query, key).Scan(
		&s.ID,
		&s.Key,
		&s.Value,
		&s.Description,
		&s.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return s, nil
}

// Update 更新设置
func (r *ServerSettingRepository) Update(key, value string) error {
	query := `
		UPDATE server_settings
		SET value = $1
		WHERE key = $2
	`

	_, err := r.DB.Exec(query, value, key)
	return err
}

// Create 创建设置
func (r *ServerSettingRepository) Create(key, value, description string) error {
	query := `
		INSERT INTO server_settings (key, value, description)
		VALUES ($1, $2, $3)
	`

	_, err := r.DB.Exec(query, key, value, description)
	return err
}

// Upsert 创建或更新设置
func (r *ServerSettingRepository) Upsert(key, value, description string) error {
	query := `
		INSERT INTO server_settings (key, value, description)
		VALUES ($1, $2, $3)
		ON CONFLICT (key) DO UPDATE
		SET value = $2, description = $3
	`

	_, err := r.DB.Exec(query, key, value, description)
	return err
}

