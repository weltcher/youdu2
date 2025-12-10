package main

import (
	"time"
	"youdu-server/config"
	"youdu-server/db"
	"youdu-server/models"
	"youdu-server/routes"
	"youdu-server/utils"
	ws "youdu-server/websocket"
)

func main() {
	// 初始化日志系统
	logFile, err := utils.InitLogger("logs")
	if err != nil {
		utils.LogFatal("日志系统初始化失败: %v", err)
	}
	defer utils.CloseLogger()
	defer logFile.Close()

	// 设置日志级别（可选，默认为INFO）
	utils.SetLogLevel(utils.DEBUG) // 开发环境开启DEBUG日志

	utils.LogInfo("========== 应用启动 ==========")

	// 加载配置
	config.LoadConfig()
	utils.LogInfo("✅ 配置加载成功")

	// 初始化数据库
	if err := db.InitDB(); err != nil {
		utils.LogFatal("数据库连接失败: %v", err)
	}
	defer db.CloseDB()
	utils.LogInfo("✅ 数据库连接成功")

	// 初始化Redis
	if err := utils.InitRedis(
		config.AppConfig.RedisHost,
		config.AppConfig.RedisPort,
		config.AppConfig.RedisPassword,
		config.AppConfig.RedisDB,
	); err != nil {
		utils.LogFatal("Redis连接失败: %v", err)
	}
	utils.LogInfo("✅ Redis连接成功")

	// 加载已解散的群组到内存
	disbandedManager := models.GetDisbandedGroupsManager()
	if err := disbandedManager.LoadDisbandedGroups(); err != nil {
		utils.LogFatal("加载已解散群组失败: %v", err)
	}
	utils.LogInfo("✅ 已解散群组管理器初始化成功")

	// 创建并启动WebSocket Hub
	hub := ws.NewHub()
	go hub.Run()
	utils.LogInfo("✅ WebSocket Hub已启动")

	// 启动心跳检查定时器（每15秒检查一次）
	go func() {
		ticker := time.NewTicker(15 * time.Second)
		defer ticker.Stop()
		for range ticker.C {
			hub.CheckHeartbeat()
		}
	}()

	// 设置HTTP API路由
	apiRouter := routes.SetupRouter(hub)

	// 设置WebSocket路由（独立端口）
	wsRouter := routes.SetupWebSocketRouter(hub)

	// 启动HTTP API服务器
	serverAddr := config.AppConfig.ServerHost + ":" + config.AppConfig.ServerPort
	utils.LogInfo("🚀 HTTP API服务器启动在 http://%s", serverAddr)

	// 启动WebSocket服务器（独立端口）
	wsAddr := config.AppConfig.WSHost + ":" + config.AppConfig.WSPort
	utils.LogInfo("🚀 WebSocket服务器启动在 ws://%s", wsAddr)

	// 在单独的goroutine中启动WebSocket服务器
	go func() {
		if err := wsRouter.Run(wsAddr); err != nil {
			utils.LogFatal("WebSocket服务器启动失败: %v", err)
		}
	}()

	// 启动HTTP API服务器（主线程）
	if err := apiRouter.Run(serverAddr); err != nil {
		utils.LogFatal("HTTP API服务器启动失败: %v", err)
	}
}
