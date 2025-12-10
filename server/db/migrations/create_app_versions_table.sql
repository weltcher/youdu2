-- Create application version upgrade information table
-- Used to store version upgrade information for various platforms
CREATE TABLE IF NOT EXISTS app_versions (
    id SERIAL PRIMARY KEY,
    version VARCHAR(50) NOT NULL,                    -- Version number, e.g. 1.0.0, 1.2.3
    platform VARCHAR(20) NOT NULL,                   -- Platform: windows, android, ios
    distribution_type VARCHAR(20) DEFAULT 'oss',     -- Distribution type: oss(OSS file), url(external link, e.g. TestFlight)
    package_url TEXT,                                -- Upgrade package download address/distribution address
    oss_object_key VARCHAR(500),                     -- OSS object key (only for oss type)
    release_notes TEXT,                              -- Upgrade description information
    status VARCHAR(20) DEFAULT 'draft',              -- Status: draft, published, deprecated
    is_force_update BOOLEAN DEFAULT FALSE,          -- Whether to force update
    min_supported_version VARCHAR(50),               -- Minimum supported version (versions below this must update)
    file_size BIGINT DEFAULT 0,                      -- File size (bytes, only for oss type)
    file_hash VARCHAR(128),                          -- File MD5/SHA256 hash value (only for oss type)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    published_at TIMESTAMP WITH TIME ZONE,           -- Published time
    created_by VARCHAR(100),                         -- Creator
    UNIQUE(version, platform)                        -- Same version on same platform is unique
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_app_versions_platform ON app_versions(platform);
CREATE INDEX IF NOT EXISTS idx_app_versions_status ON app_versions(status);
CREATE INDEX IF NOT EXISTS idx_app_versions_platform_status ON app_versions(platform, status);

-- Add comments
COMMENT ON TABLE app_versions IS 'Application version upgrade information table';
COMMENT ON COLUMN app_versions.version IS 'Version number';
COMMENT ON COLUMN app_versions.platform IS 'Platform: windows, android, ios';
COMMENT ON COLUMN app_versions.distribution_type IS 'Distribution type: oss(OSS file), url(external link like TestFlight)';
COMMENT ON COLUMN app_versions.package_url IS 'Upgrade package download address/distribution address';
COMMENT ON COLUMN app_versions.oss_object_key IS 'OSS object storage key (only for oss type)';
COMMENT ON COLUMN app_versions.release_notes IS 'Upgrade description information';
COMMENT ON COLUMN app_versions.status IS 'Status: draft, published, deprecated';
COMMENT ON COLUMN app_versions.is_force_update IS 'Whether to force update';
COMMENT ON COLUMN app_versions.min_supported_version IS 'Minimum supported version';
COMMENT ON COLUMN app_versions.file_size IS 'File size (bytes, only for oss type)';
COMMENT ON COLUMN app_versions.file_hash IS 'File hash value (only for oss type)';
