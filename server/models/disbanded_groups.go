package models

import (
	"sync"
	"youdu-server/db"
	"youdu-server/utils"
)

// DisbandedGroupsManager 已解散群组管理器
type DisbandedGroupsManager struct {
	groups map[int]bool // 已解散的群组ID映射
	mu     sync.RWMutex // 读写锁，保证并发安全
}

var disbandedGroupsManager *DisbandedGroupsManager
var once sync.Once

// GetDisbandedGroupsManager 获取已解散群组管理器单例
func GetDisbandedGroupsManager() *DisbandedGroupsManager {
	once.Do(func() {
		disbandedGroupsManager = &DisbandedGroupsManager{
			groups: make(map[int]bool),
		}
	})
	return disbandedGroupsManager
}

// LoadDisbandedGroups 从数据库加载已解散的群组
func (dgm *DisbandedGroupsManager) LoadDisbandedGroups() error {
	dgm.mu.Lock()
	defer dgm.mu.Unlock()

	// 查询所有已解散的群组（deleted_at不为NULL）
	query := `
		SELECT id
		FROM groups
		WHERE deleted_at IS NOT NULL
	`

	rows, err := db.DB.Query(query)
	if err != nil {
		utils.LogDebug("查询已解散群组失败: %v", err)
		return err
	}
	defer rows.Close()

	// 清空现有map
	dgm.groups = make(map[int]bool)

	// 加载所有已解散的群组ID
	count := 0
	for rows.Next() {
		var groupID int
		if err := rows.Scan(&groupID); err != nil {
			utils.LogDebug("扫描已解散群组ID失败: %v", err)
			continue
		}
		dgm.groups[groupID] = true
		count++
	}

	utils.LogInfo("✅ 已加载 %d 个已解散的群组到内存", count)
	return nil
}

// AddDisbandedGroup 添加已解散的群组ID
func (dgm *DisbandedGroupsManager) AddDisbandedGroup(groupID int) {
	dgm.mu.Lock()
	defer dgm.mu.Unlock()
	dgm.groups[groupID] = true
	utils.LogDebug("✅ 已添加已解散群组到内存: 群组ID=%d", groupID)
}

// IsGroupDisbanded 检查群组是否已解散
func (dgm *DisbandedGroupsManager) IsGroupDisbanded(groupID int) bool {
	dgm.mu.RLock()
	defer dgm.mu.RUnlock()
	return dgm.groups[groupID]
}

// RemoveDisbandedGroup 移除已解散的群组ID（如果需要恢复群组时使用）
func (dgm *DisbandedGroupsManager) RemoveDisbandedGroup(groupID int) {
	dgm.mu.Lock()
	defer dgm.mu.Unlock()
	delete(dgm.groups, groupID)
	utils.LogDebug("✅ 已从内存移除已解散群组: 群组ID=%d", groupID)
}

// GetDisbandedGroupsCount 获取已解散群组的数量
func (dgm *DisbandedGroupsManager) GetDisbandedGroupsCount() int {
	dgm.mu.RLock()
	defer dgm.mu.RUnlock()
	return len(dgm.groups)
}
