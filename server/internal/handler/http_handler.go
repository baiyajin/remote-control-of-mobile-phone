package handler

import (
	"fmt"
	"net/http"
	"remote-control/server/internal/config"
	"remote-control/server/internal/service"

	"github.com/gin-gonic/gin"
)

type HTTPHandler struct {
	deviceService     *service.DeviceService
	connectionService *service.ConnectionService
	logService        *service.LogService
	configManager     *config.ConfigManager
}

func NewHTTPHandler(deviceService *service.DeviceService, connectionService *service.ConnectionService, logService *service.LogService) *HTTPHandler {
	return &HTTPHandler{
		deviceService:     deviceService,
		connectionService: connectionService,
		logService:        logService,
		configManager:     config.GetConfigManager(),
	}
}

func (h *HTTPHandler) GetServerStatus(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "running",
		"connections": h.connectionService.GetConnectionCount(),
	})
}

func (h *HTTPHandler) GetServerConfig(c *gin.Context) {
	cfg := h.configManager.GetConfig()
	c.JSON(http.StatusOK, cfg)
}

func (h *HTTPHandler) UpdateServerConfig(c *gin.Context) {
	var newConfig config.Config
	if err := c.ShouldBindJSON(&newConfig); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.configManager.UpdateConfig(&newConfig); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "配置更新成功"})
}

func (h *HTTPHandler) GetServerLogs(c *gin.Context) {
	limit := 100
	if limitStr := c.Query("limit"); limitStr != "" {
		if parsedLimit, err := parseInt(limitStr); err == nil && parsedLimit > 0 {
			limit = parsedLimit
		}
	}

	logs := h.logService.GetLogs(limit)
	c.JSON(http.StatusOK, gin.H{
		"logs": logs,
		"count": len(logs),
	})
}

func parseInt(s string) (int, error) {
	var result int
	_, err := fmt.Sscanf(s, "%d", &result)
	return result, err
}

func (h *HTTPHandler) GetServerStats(c *gin.Context) {
	devices, _ := h.deviceService.GetDeviceList()
	c.JSON(http.StatusOK, gin.H{
		"total_devices": len(devices),
		"online_devices": h.connectionService.GetConnectionCount(),
		"connections": h.connectionService.GetConnectionCount(),
	})
}

func (h *HTTPHandler) GetDeviceList(c *gin.Context) {
	devices, err := h.deviceService.GetDeviceList()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"devices": devices,
	})
}

func (h *HTTPHandler) RegisterDevice(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "设备注册功能待实现（通过 WebSocket）",
	})
}

