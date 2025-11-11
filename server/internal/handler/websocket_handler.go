package handler

import (
	"log"
	"net/http"
	"remote-control/server/internal/service"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // 开发阶段允许所有来源
	},
}

type WebSocketHandler struct {
	deviceService     *service.DeviceService
	connectionService *service.ConnectionService
}

func NewWebSocketHandler(deviceService *service.DeviceService, connectionService *service.ConnectionService) *WebSocketHandler {
	return &WebSocketHandler{
		deviceService:     deviceService,
		connectionService: connectionService,
	}
}

func (h *WebSocketHandler) HandleWebSocket(c *gin.Context) {
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("WebSocket 升级失败: %v", err)
		return
	}
	defer conn.Close()

	log.Println("新的 WebSocket 连接建立")

	// 处理连接（具体逻辑待实现）
	for {
		messageType, message, err := conn.ReadMessage()
		if err != nil {
			log.Printf("读取消息失败: %v", err)
			break
		}

		log.Printf("收到消息类型: %d, 内容: %s", messageType, string(message))

		// 回显消息（临时）
		if err := conn.WriteMessage(messageType, message); err != nil {
			log.Printf("发送消息失败: %v", err)
			break
		}
	}

	log.Println("WebSocket 连接关闭")
}

