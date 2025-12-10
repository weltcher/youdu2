package websocket

import (
	"sync"
	"time"
	"youdu-server/utils"
)

// Client 表示一个WebSocket客户端连接
type Client struct {
	UserID      int
	Conn        *Conn
	Send        chan []byte
	closed      bool       // 标记 Send channel 是否已关闭
	mu          sync.Mutex // 保护 closed 标志
	missedPings int        // 连续错过的ping消息次数
	pingMu      sync.Mutex // 保护 missedPings 计数器
}

// Hub 维护活动的客户端连接和消息广播
type Hub struct {
	// 已注册的客户端 (userID -> Client)
	clients map[int]*Client

	// 客户端注册请求
	Register chan *Client

	// 客户端注销请求
	Unregister chan *Client

	// 消息广播
	Broadcast chan *BroadcastMessage

	// 互斥锁保护clients map
	mu sync.RWMutex

	// 离线通知回调函数
	OnUserOffline func(userID int)
}

// BroadcastMessage 广播消息结构
type BroadcastMessage struct {
	UserID  int    // 目标用户ID
	Message []byte // 消息内容
}

// NewHub 创建新的Hub
func NewHub() *Hub {
	return &Hub{
		clients:    make(map[int]*Client),
		Register:   make(chan *Client),
		Unregister: make(chan *Client),
		Broadcast:  make(chan *BroadcastMessage),
	}
}

// closeSend 安全地关闭客户端的 Send channel
func (c *Client) closeSend() {
	c.mu.Lock()
	defer c.mu.Unlock()
	if !c.closed {
		close(c.Send)
		c.closed = true
	}
}

// ResetPingCounter 重置ping计数器（收到ping消息时调用）
func (c *Client) ResetPingCounter() {
	c.pingMu.Lock()
	defer c.pingMu.Unlock()
	c.missedPings = 0
}

// IncrementMissedPings 增加错过的ping次数
func (c *Client) IncrementMissedPings() int {
	c.pingMu.Lock()
	defer c.pingMu.Unlock()
	c.missedPings++
	return c.missedPings
}

// GetMissedPings 获取错过的ping次数
func (c *Client) GetMissedPings() int {
	c.pingMu.Lock()
	defer c.pingMu.Unlock()
	return c.missedPings
}

// Run 启动Hub
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.Register:
			h.mu.Lock()
			// 如果用户已经有连接，向旧连接发送被踢下线通知
			if oldClient, ok := h.clients[client.UserID]; ok {
				utils.LogDebug("🔄 [Hub] 检测到用户 %d 重复登录，向旧设备发送通知并强制断开", client.UserID)

				// 先从map中删除旧设备，避免新设备收到踢人消息
				delete(h.clients, client.UserID)
				utils.LogDebug("🗑️ [Hub] 已从在线列表移除用户 %d 的旧设备", client.UserID)

				// 向旧连接发送被踢下线通知
				kickedMessage := []byte(`{"type":"forced_logout","message":"您的账号已在其他设备登录"}`)

				// 解锁后发送消息并关闭连接，避免阻塞
				h.mu.Unlock()

				// 尝试发送消息（非阻塞）
				select {
				case oldClient.Send <- kickedMessage:
					utils.LogDebug("✅ [Hub] 已向用户 %d 的旧设备发送踢下线通知", client.UserID)
				case <-time.After(100 * time.Millisecond):
					utils.LogDebug("⏱️ [Hub] 向用户 %d 的旧设备发送通知超时，直接关闭", client.UserID)
				}

				// 立即关闭旧连接的Send通道，确保旧设备完全失效
				oldClient.closeSend()
				utils.LogDebug("🔒 [Hub] 已关闭用户 %d 旧设备的Send通道", client.UserID)

				// 等待100ms让旧设备的连接完全清理
				time.Sleep(100 * time.Millisecond)

				// 重新加锁，注册新设备
				h.mu.Lock()
				utils.LogDebug("📝 [Hub] 旧设备已完全断开，准备注册新设备")
			}

			// 注册新连接
			h.clients[client.UserID] = client
			h.mu.Unlock()
			utils.LogDebug("✅ [Hub] 用户 %d 新设备已连接 (总连接数: %d)", client.UserID, len(h.clients))

			// 打印当前所有在线用户ID
			h.mu.RLock()
			var onlineUserIDs []int
			for userID := range h.clients {
				onlineUserIDs = append(onlineUserIDs, userID)
			}
			h.mu.RUnlock()
			utils.LogDebug("📊 [Hub] 当前在线用户ID列表: %v", onlineUserIDs)

		case client := <-h.Unregister:
			h.mu.Lock()
			// 检查要断开的连接是否真的是当前在线的连接
			// 避免误删新连接（旧连接断开时，新连接可能已经注册）
			if currentClient, ok := h.clients[client.UserID]; ok {
				// 只有当前连接和要断开的连接是同一个，才删除
				if currentClient == client {
					delete(h.clients, client.UserID)
					client.closeSend()
					utils.LogDebug("🔌 [Hub] 用户 %d 已断开连接 (总连接数: %d)", client.UserID, len(h.clients))

					// 调用离线通知回调（在锁外执行，避免死锁）
					userID := client.UserID
					h.mu.Unlock()
					if h.OnUserOffline != nil {
						go h.OnUserOffline(userID)
					}
				} else {
					// 这是旧连接断开，但新连接已经注册，忽略
					h.mu.Unlock()
					utils.LogDebug("ℹ️ [Hub] 用户 %d 的旧连接断开，新连接已接管", client.UserID)
				}
			} else {
				h.mu.Unlock()
				utils.LogDebug("⚠️ [Hub] 用户 %d 尝试断开但不在在线列表中", client.UserID)
			}

		case message := <-h.Broadcast:
			h.mu.RLock()
			client, ok := h.clients[message.UserID]
			totalOnlineUsers := len(h.clients)
			h.mu.RUnlock()

			utils.LogDebug("🔄 [Hub] 收到广播消息 - 目标用户ID: %d, 用户在线: %v, 当前在线总数: %d", message.UserID, ok, totalOnlineUsers)

			if ok {
				select {
				case client.Send <- message.Message:
					// 消息发送成功
					utils.LogDebug("✅ [Hub] 消息成功发送到用户 %d 的Send通道 (通道缓冲区可用)", message.UserID)
				default:
					// 发送失败，关闭连接
					h.mu.Lock()
					client.closeSend()
					delete(h.clients, client.UserID)
					h.mu.Unlock()
					utils.LogDebug("❌ [Hub] 用户 %d 消息发送失败，连接已关闭", client.UserID)
				}
			} else {
				utils.LogDebug("⚠️ [Hub] 用户 %d 不在线，无法发送消息", message.UserID)
			}
		}
	}
}

// IsUserOnline 检查用户是否在线
func (h *Hub) IsUserOnline(userID int) bool {
	h.mu.RLock()
	defer h.mu.RUnlock()
	_, ok := h.clients[userID]
	return ok
}

// GetOnlineUserCount 获取在线用户数
func (h *Hub) GetOnlineUserCount() int {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return len(h.clients)
}

// SendToUser 向指定用户发送消息
func (h *Hub) SendToUser(userID int, message []byte) bool {
	h.Broadcast <- &BroadcastMessage{
		UserID:  userID,
		Message: message,
	}
	return h.IsUserOnline(userID)
}

// BroadcastToChannel 向频道中的所有在线用户广播消息（排除指定用户）
func (h *Hub) BroadcastToChannel(channelName string, message []byte, excludeUserID int) {
	utils.LogDebug("📢 [Hub] 开始向频道 %s 广播消息，排除用户 %d", channelName, excludeUserID)

	// 从频道名称中解析出相关的用户ID
	// 频道名称格式: group_call_${callerId}_${timestamp}
	// 我们需要一个更好的方式来跟踪频道中的用户，这里先实现一个简化版本

	h.mu.RLock()
	var sentCount int
	for userID, client := range h.clients {
		// 跳过排除的用户
		if userID == excludeUserID {
			continue
		}

		// 发送消息给所有其他在线用户（简化实现）
		// 在实际应用中，应该维护频道-用户的映射关系
		select {
		case client.Send <- message:
			sentCount++
			utils.LogDebug("✅ [Hub] 频道广播消息已发送给用户 %d", userID)
		default:
			utils.LogDebug("❌ [Hub] 向用户 %d 发送频道广播消息失败", userID)
		}
	}
	h.mu.RUnlock()

	utils.LogDebug("📢 [Hub] 频道 %s 广播完成，成功发送给 %d 个用户", channelName, sentCount)
}

// BroadcastToUsers 向指定的用户列表广播消息（排除指定用户）
func (h *Hub) BroadcastToUsers(userIDs []int, message []byte, excludeUserID int) {
	utils.LogDebug("📢 [Hub] 开始向用户列表广播消息，目标用户: %v，排除用户: %d", userIDs, excludeUserID)

	h.mu.RLock()
	var sentCount int
	for _, userID := range userIDs {
		// 跳过排除的用户
		if userID == excludeUserID {
			continue
		}

		// 检查用户是否在线
		if client, ok := h.clients[userID]; ok {
			select {
			case client.Send <- message:
				sentCount++
				utils.LogDebug("✅ [Hub] 广播消息已发送给用户 %d", userID)
			default:
				utils.LogDebug("❌ [Hub] 向用户 %d 发送广播消息失败", userID)
			}
		} else {
			utils.LogDebug("⚠️ [Hub] 用户 %d 不在线，跳过发送", userID)
		}
	}
	h.mu.RUnlock()

	utils.LogDebug("📢 [Hub] 用户列表广播完成，成功发送给 %d 个用户", sentCount)
}

// BroadcastGroupDisbanded 广播群组解散通知（占位方法）
// 实际的通知逻辑在控制器中处理
func (h *Hub) BroadcastGroupDisbanded(groupID int) {
	utils.LogDebug("📢 [Hub] 群组 %d 已被解散", groupID)
}

// CheckHeartbeat 检查所有客户端的心跳状态
// 增加所有客户端的missedPings计数，如果达到2次则断开连接
func (h *Hub) CheckHeartbeat() {
	h.mu.Lock()
	var disconnectedClients []*Client

	for userID, client := range h.clients {
		missedPings := client.IncrementMissedPings()

		if missedPings >= 2 {
			disconnectedClients = append(disconnectedClients, client)
			delete(h.clients, userID)
		}
	}
	h.mu.Unlock()

	// 在锁外关闭连接并触发离线回调
	for _, client := range disconnectedClients {
		client.closeSend()

		if h.OnUserOffline != nil {
			go h.OnUserOffline(client.UserID)
		}
	}
}
