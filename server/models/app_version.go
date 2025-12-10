package models

import (
	"database/sql"
	"fmt"
	"time"
)

// AppVersion 应用版本模型
type AppVersion struct {
	ID                  int        `json:"id"`
	Version             string     `json:"version"`
	Platform            string     `json:"platform"`
	DistributionType    string     `json:"distribution_type"` // oss: OSS文件, url: 外部链接(如TestFlight)
	PackageURL          *string    `json:"package_url"`
	OSSObjectKey        *string    `json:"oss_object_key"`
	ReleaseNotes        *string    `json:"release_notes"`
	Status              string     `json:"status"`
	IsForceUpdate       bool       `json:"is_force_update"`
	MinSupportedVersion *string    `json:"min_supported_version"`
	FileSize            int64      `json:"file_size"`
	FileHash            *string    `json:"file_hash"`
	CreatedAt           time.Time  `json:"created_at"`
	UpdatedAt           time.Time  `json:"updated_at"`
	PublishedAt         *time.Time `json:"published_at"`
	CreatedBy           *string    `json:"created_by"`
}

// CreateAppVersionRequest 创建版本请求
type CreateAppVersionRequest struct {
	Version             string  `json:"version" binding:"required"`
	Platform            string  `json:"platform" binding:"required,oneof=windows android ios"`
	DistributionType    string  `json:"distribution_type"` // oss: OSS文件, url: 外部链接(如TestFlight)
	PackageURL          *string `json:"package_url"`
	OSSObjectKey        *string `json:"oss_object_key"`
	ReleaseNotes        *string `json:"release_notes"`
	IsForceUpdate       bool    `json:"is_force_update"`
	MinSupportedVersion *string `json:"min_supported_version"`
	FileSize            int64   `json:"file_size"`
	FileHash            *string `json:"file_hash"`
}

// UpdateAppVersionRequest 更新版本请求
type UpdateAppVersionRequest struct {
	PackageURL          *string `json:"package_url"`
	OSSObjectKey        *string `json:"oss_object_key"`
	ReleaseNotes        *string `json:"release_notes"`
	Status              *string `json:"status"`
	IsForceUpdate       *bool   `json:"is_force_update"`
	MinSupportedVersion *string `json:"min_supported_version"`
	FileSize            *int64  `json:"file_size"`
	FileHash            *string `json:"file_hash"`
}

// AppVersionRepository 版本数据仓库
type AppVersionRepository struct {
	DB *sql.DB
}

// NewAppVersionRepository 创建版本仓库
func NewAppVersionRepository(db *sql.DB) *AppVersionRepository {
	return &AppVersionRepository{DB: db}
}


// Create 创建版本记录
func (r *AppVersionRepository) Create(req CreateAppVersionRequest, createdBy string) (*AppVersion, error) {
	// 默认分发类型为oss
	distributionType := req.DistributionType
	if distributionType == "" {
		distributionType = "oss"
	}

	query := `
		INSERT INTO app_versions (version, platform, distribution_type, package_url, oss_object_key, release_notes, 
			is_force_update, min_supported_version, file_size, file_hash, created_by, status)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'draft')
		RETURNING id, version, platform, distribution_type, package_url, oss_object_key, release_notes, status,
			is_force_update, min_supported_version, file_size, file_hash, created_at, updated_at, 
			published_at, created_by
	`

	version := &AppVersion{}
	err := r.DB.QueryRow(query,
		req.Version, req.Platform, distributionType, req.PackageURL, req.OSSObjectKey, req.ReleaseNotes,
		req.IsForceUpdate, req.MinSupportedVersion, req.FileSize, req.FileHash, createdBy,
	).Scan(
		&version.ID, &version.Version, &version.Platform, &version.DistributionType, &version.PackageURL, &version.OSSObjectKey,
		&version.ReleaseNotes, &version.Status, &version.IsForceUpdate, &version.MinSupportedVersion,
		&version.FileSize, &version.FileHash, &version.CreatedAt, &version.UpdatedAt,
		&version.PublishedAt, &version.CreatedBy,
	)

	if err != nil {
		return nil, err
	}
	return version, nil
}

// FindByID 根据ID查找版本
func (r *AppVersionRepository) FindByID(id int) (*AppVersion, error) {
	query := `
		SELECT id, version, platform, distribution_type, package_url, oss_object_key, release_notes, status,
			is_force_update, min_supported_version, file_size, file_hash, created_at, updated_at, 
			published_at, created_by
		FROM app_versions WHERE id = $1
	`

	version := &AppVersion{}
	err := r.DB.QueryRow(query, id).Scan(
		&version.ID, &version.Version, &version.Platform, &version.DistributionType, &version.PackageURL, &version.OSSObjectKey,
		&version.ReleaseNotes, &version.Status, &version.IsForceUpdate, &version.MinSupportedVersion,
		&version.FileSize, &version.FileHash, &version.CreatedAt, &version.UpdatedAt,
		&version.PublishedAt, &version.CreatedBy,
	)

	if err != nil {
		return nil, err
	}
	return version, nil
}

// FindByVersionAndPlatform 根据版本号和平台查找
func (r *AppVersionRepository) FindByVersionAndPlatform(version, platform string) (*AppVersion, error) {
	query := `
		SELECT id, version, platform, distribution_type, package_url, oss_object_key, release_notes, status,
			is_force_update, min_supported_version, file_size, file_hash, created_at, updated_at, 
			published_at, created_by
		FROM app_versions WHERE version = $1 AND platform = $2
	`

	v := &AppVersion{}
	err := r.DB.QueryRow(query, version, platform).Scan(
		&v.ID, &v.Version, &v.Platform, &v.DistributionType, &v.PackageURL, &v.OSSObjectKey,
		&v.ReleaseNotes, &v.Status, &v.IsForceUpdate, &v.MinSupportedVersion,
		&v.FileSize, &v.FileHash, &v.CreatedAt, &v.UpdatedAt,
		&v.PublishedAt, &v.CreatedBy,
	)

	if err != nil {
		return nil, err
	}
	return v, nil
}

// GetLatestByPlatform 获取指定平台的最新已发布版本
func (r *AppVersionRepository) GetLatestByPlatform(platform string) (*AppVersion, error) {
	query := `
		SELECT id, version, platform, distribution_type, package_url, oss_object_key, release_notes, status,
			is_force_update, min_supported_version, file_size, file_hash, created_at, updated_at, 
			published_at, created_by
		FROM app_versions 
		WHERE platform = $1 AND status = 'published'
		ORDER BY published_at DESC LIMIT 1
	`

	version := &AppVersion{}
	err := r.DB.QueryRow(query, platform).Scan(
		&version.ID, &version.Version, &version.Platform, &version.DistributionType, &version.PackageURL, &version.OSSObjectKey,
		&version.ReleaseNotes, &version.Status, &version.IsForceUpdate, &version.MinSupportedVersion,
		&version.FileSize, &version.FileHash, &version.CreatedAt, &version.UpdatedAt,
		&version.PublishedAt, &version.CreatedBy,
	)

	if err != nil {
		return nil, err
	}
	return version, nil
}

// GetPreviousVersion 获取指定平台的上一个版本
func (r *AppVersionRepository) GetPreviousVersion(platform string, currentVersionID int) (*AppVersion, error) {
	query := `
		SELECT id, version, platform, distribution_type, package_url, oss_object_key, release_notes, status,
			is_force_update, min_supported_version, file_size, file_hash, created_at, updated_at, 
			published_at, created_by
		FROM app_versions 
		WHERE platform = $1 AND id < $2 AND status = 'published'
		ORDER BY id DESC LIMIT 1
	`

	version := &AppVersion{}
	err := r.DB.QueryRow(query, platform, currentVersionID).Scan(
		&version.ID, &version.Version, &version.Platform, &version.DistributionType, &version.PackageURL, &version.OSSObjectKey,
		&version.ReleaseNotes, &version.Status, &version.IsForceUpdate, &version.MinSupportedVersion,
		&version.FileSize, &version.FileHash, &version.CreatedAt, &version.UpdatedAt,
		&version.PublishedAt, &version.CreatedBy,
	)

	if err != nil {
		return nil, err
	}
	return version, nil
}

// List 获取版本列表
func (r *AppVersionRepository) List(platform, status string, page, pageSize int) ([]*AppVersion, int, error) {
	// 构建查询条件
	whereClause := "WHERE 1=1"
	args := []interface{}{}
	argIndex := 1

	if platform != "" {
		whereClause += fmt.Sprintf(" AND platform = $%d", argIndex)
		args = append(args, platform)
		argIndex++
	}
	if status != "" {
		whereClause += fmt.Sprintf(" AND status = $%d", argIndex)
		args = append(args, status)
		argIndex++
	}

	// 获取总数
	countQuery := "SELECT COUNT(*) FROM app_versions " + whereClause
	var total int
	err := r.DB.QueryRow(countQuery, args...).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	// 获取列表
	offset := (page - 1) * pageSize
	listQuery := fmt.Sprintf(`
		SELECT id, version, platform, distribution_type, package_url, oss_object_key, release_notes, status,
			is_force_update, min_supported_version, file_size, file_hash, created_at, updated_at, 
			published_at, created_by
		FROM app_versions %s
		ORDER BY created_at DESC
		LIMIT $%d OFFSET $%d`, whereClause, argIndex, argIndex+1)

	args = append(args, pageSize, offset)

	rows, err := r.DB.Query(listQuery, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	versions := []*AppVersion{}
	for rows.Next() {
		v := &AppVersion{}
		err := rows.Scan(
			&v.ID, &v.Version, &v.Platform, &v.DistributionType, &v.PackageURL, &v.OSSObjectKey,
			&v.ReleaseNotes, &v.Status, &v.IsForceUpdate, &v.MinSupportedVersion,
			&v.FileSize, &v.FileHash, &v.CreatedAt, &v.UpdatedAt,
			&v.PublishedAt, &v.CreatedBy,
		)
		if err != nil {
			return nil, 0, err
		}
		versions = append(versions, v)
	}

	return versions, total, nil
}

// Update 更新版本信息
func (r *AppVersionRepository) Update(id int, req UpdateAppVersionRequest) error {
	query := `
		UPDATE app_versions SET
			package_url = COALESCE($1, package_url),
			oss_object_key = COALESCE($2, oss_object_key),
			release_notes = COALESCE($3, release_notes),
			status = COALESCE($4, status),
			is_force_update = COALESCE($5, is_force_update),
			min_supported_version = COALESCE($6, min_supported_version),
			file_size = COALESCE($7, file_size),
			file_hash = COALESCE($8, file_hash),
			updated_at = CURRENT_TIMESTAMP
		WHERE id = $9
	`

	_, err := r.DB.Exec(query,
		req.PackageURL, req.OSSObjectKey, req.ReleaseNotes, req.Status,
		req.IsForceUpdate, req.MinSupportedVersion, req.FileSize, req.FileHash, id,
	)
	return err
}

// Publish 发布版本
func (r *AppVersionRepository) Publish(id int) error {
	query := `
		UPDATE app_versions SET
			status = 'published',
			published_at = CURRENT_TIMESTAMP,
			updated_at = CURRENT_TIMESTAMP
		WHERE id = $1
	`
	_, err := r.DB.Exec(query, id)
	return err
}

// Deprecate 废弃版本
func (r *AppVersionRepository) Deprecate(id int) error {
	query := `
		UPDATE app_versions SET
			status = 'deprecated',
			updated_at = CURRENT_TIMESTAMP
		WHERE id = $1
	`
	_, err := r.DB.Exec(query, id)
	return err
}

// Delete 删除版本
func (r *AppVersionRepository) Delete(id int) error {
	query := `DELETE FROM app_versions WHERE id = $1`
	_, err := r.DB.Exec(query, id)
	return err
}
