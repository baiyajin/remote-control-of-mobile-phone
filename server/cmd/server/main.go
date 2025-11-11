package main

import (
	"log"
	"remote-control/server/internal/config"
	"remote-control/server/internal/database"
	"remote-control/server/internal/handler"
	"remote-control/server/internal/service"

	"github.com/gin-gonic/gin"
)

func main() {
	// 加载配置
	cfg := config.Load()

	// 初始化数据库
	db, err := database.Init(cfg.Database.Path)
	if err != nil {
		log.Fatalf("数据库初始化失败: %v", err)
	}

	// 初始化服务
	deviceService := service.NewDeviceService(db)
	connectionService := service.NewConnectionService()
	logService := service.NewLogService(1000)

	// 初始化处理器
	wsHandler := handler.NewWebSocketHandler(deviceService, connectionService)
	httpHandler := handler.NewHTTPHandler(deviceService, connectionService, logService)

	// 设置路由
	router := gin.Default()

	// WebSocket 路由
	router.GET("/ws", wsHandler.HandleWebSocket)

	// HTTP API 路由
	api := router.Group("/api")
	{
		// 服务器管理
		api.GET("/server/status", httpHandler.GetServerStatus)
		api.GET("/server/config", httpHandler.GetServerConfig)
		api.POST("/server/config", httpHandler.UpdateServerConfig)
		api.GET("/server/logs", httpHandler.GetServerLogs)
		api.GET("/server/stats", httpHandler.GetServerStats)

		// 设备管理
		api.GET("/devices", httpHandler.GetDeviceList)
		api.POST("/devices/register", httpHandler.RegisterDevice)
	}

	// 启动服务器
	addr := cfg.Server.Host + ":" + cfg.Server.Port
	log.Printf("服务器启动在 %s", addr)
	if err := router.Run(addr); err != nil {
		log.Fatalf("服务器启动失败: %v", err)
	}
}

