package handler

import (
	"net/http"
	"remote-control/server/internal/service"

	"github.com/gin-gonic/gin"
)

type HTTPHandler struct {
	deviceService     *service.DeviceService
	connectionService *service.ConnectionService
}

func NewHTTPHandler(deviceService *service.DeviceService, connectionService *service.ConnectionService) *HTTPHandler {
	return &HTTPHandler{
		deviceService:     deviceService,
		connectionService: connectionService,
	}
}

func (h *HTTPHandler) GetServerStatus(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "running",
		"connections": h.connectionService.GetConnectionCount(),
	})
}

func (h *HTTPHandler) GetServerConfig(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "配置获取功能待实现",
	})
}

func (h *HTTPHandler) UpdateServerConfig(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "配置更新功能待实现",
	})
}

func (h *HTTPHandler) GetServerLogs(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "日志获取功能待实现",
	})
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

