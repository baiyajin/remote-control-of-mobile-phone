package handler

import (
	"encoding/json"
	"log"
	"net/http"
	"remote-control/server/internal/model"
	"remote-control/server/internal/service"
	"remote-control/server/pkg/protocol"
	"time"

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

	var deviceID string

	// 处理消息循环
	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			log.Printf("读取消息失败: %v", err)
			break
		}

		var msg protocol.Message
		if err := json.Unmarshal(message, &msg); err != nil {
			log.Printf("解析消息失败: %v", err)
			continue
		}

		// 处理不同类型的消息
		response := h.handleMessage(&msg, conn, &deviceID)
		if response != nil {
			if err := conn.WriteJSON(response); err != nil {
				log.Printf("发送响应失败: %v", err)
				break
			}
		}
	}

	// 清理连接
	if deviceID != "" {
		h.connectionService.RemoveConnection(deviceID)
		log.Printf("设备 %s 断开连接", deviceID)
	}
}

func (h *WebSocketHandler) handleMessage(msg *protocol.Message, conn *websocket.Conn, deviceID *string) *protocol.Message {
	switch msg.Type {
	case "device_register":
		return h.handleDeviceRegister(msg, conn, deviceID)
	case "device_list":
		return h.handleDeviceList()
	case "connect_request":
		return h.handleConnectRequest(msg, conn, *deviceID)
	case "screen_frame":
		h.handleScreenFrame(msg, *deviceID)
		return nil // 屏幕帧不需要响应
	case "input_mouse", "input_keyboard":
		h.handleInputControl(msg, *deviceID)
		return nil // 输入控制不需要响应
	case "ping":
		return h.handlePing()
	default:
		log.Printf("未知消息类型: %s", msg.Type)
		return nil
	}
}

func (h *WebSocketHandler) handleDeviceRegister(msg *protocol.Message, conn *websocket.Conn, deviceID *string) *protocol.Message {
	var data protocol.DeviceRegisterData
	if err := json.Unmarshal(msg.Data, &data); err != nil {
		return h.errorResponse("解析设备注册数据失败")
	}

	// 保存设备信息
	device := &model.Device{
		ID:          data.DeviceID,
		Name:        data.DeviceName,
		Type:        data.DeviceType,
		IPAddress:   data.IPAddress,
		LastSeen:    time.Now(),
		CreatedAt:   time.Now(),
	}
	
	// 将 capabilities 转换为 JSON 字符串
	capabilitiesJSON, _ := json.Marshal(data.Capabilities)
	device.Capabilities = string(capabilitiesJSON)

	if err := h.deviceService.RegisterDevice(device); err != nil {
		log.Printf("设备注册失败: %v", err)
		return h.errorResponse("设备注册失败")
	}

	// 保存连接
	*deviceID = data.DeviceID
	h.connectionService.AddConnection(data.DeviceID, conn)

	log.Printf("设备注册成功: %s (%s)", data.DeviceName, data.DeviceID)

	return h.successResponse("device_register_response", map[string]interface{}{
		"status": "success",
		"device_id": data.DeviceID,
	})
}

func (h *WebSocketHandler) handleDeviceList() *protocol.Message {
	devices, err := h.deviceService.GetDeviceList()
	if err != nil {
		return h.errorResponse("获取设备列表失败")
	}

	// 获取在线设备
	connections := h.connectionService.GetAllConnections()
	onlineMap := make(map[string]bool)
	for id := range connections {
		onlineMap[id] = true
	}

	// 转换为协议格式
	deviceList := make([]protocol.DeviceInfo, 0, len(devices))
	for _, d := range devices {
		var capabilities []string
		json.Unmarshal([]byte(d.Capabilities), &capabilities)

		deviceList = append(deviceList, protocol.DeviceInfo{
			ID:          d.ID,
			Name:        d.Name,
			Type:        d.Type,
			IPAddress:   d.IPAddress,
			LastSeen:    d.LastSeen.Unix(),
			Capabilities: capabilities,
			Online:      onlineMap[d.ID],
		})
	}

	return h.successResponse("device_list", protocol.DeviceListData{
		Devices: deviceList,
	})
}

func (h *WebSocketHandler) handleConnectRequest(msg *protocol.Message, conn *websocket.Conn, controllerID string) *protocol.Message {
	var data protocol.ConnectRequestData
	if err := json.Unmarshal(msg.Data, &data); err != nil {
		return h.errorResponse("解析连接请求失败")
	}

	// 检查目标设备是否在线
	controlledConn, ok := h.connectionService.GetConnection(data.DeviceID)
	if !ok {
		return h.successResponse("connect_response", protocol.ConnectResponseData{
			Status:  "failed",
			Message: "目标设备不在线",
		})
	}

	// 生成会话ID
	sessionID := generateSessionID()

	// 创建会话
	h.connectionService.CreateSession(sessionID, controllerID, data.DeviceID)

	log.Printf("连接请求: %s -> %s (会话: %s)", controllerID, data.DeviceID, sessionID)

	// 通知被控端有连接请求
	notificationMsg := h.successResponse("notification", protocol.NotificationData{
		Title:   "连接请求",
		Message: "有设备想要连接您的设备",
		Action:  "accept",
	})
	if wsConn, ok := controlledConn.Conn.(*websocket.Conn); ok {
		wsConn.WriteJSON(notificationMsg)
	}

	return h.successResponse("connect_response", protocol.ConnectResponseData{
		Status:    "success",
		SessionID: sessionID,
	})
}

// 处理屏幕帧（从被控端转发到控制端）
func (h *WebSocketHandler) handleScreenFrame(msg *protocol.Message, controlledID string) {
	// 找到控制端
	controllerID := h.connectionService.GetControllerID(controlledID)
	if controllerID == "" {
		return
	}

	// 转发屏幕帧到控制端
	controllerConn, ok := h.connectionService.GetConnection(controllerID)
	if !ok {
		return
	}

	if wsConn, ok := controllerConn.Conn.(*websocket.Conn); ok {
		wsConn.WriteJSON(msg)
	}
}

// 处理输入控制（从控制端转发到被控端）
func (h *WebSocketHandler) handleInputControl(msg *protocol.Message, controllerID string) {
	// 找到被控端
	controlledID := h.connectionService.GetControlledID(controllerID)
	if controlledID == "" {
		return
	}

	// 转发输入控制到被控端
	controlledConn, ok := h.connectionService.GetConnection(controlledID)
	if !ok {
		return
	}

	if wsConn, ok := controlledConn.Conn.(*websocket.Conn); ok {
		wsConn.WriteJSON(msg)
	}
}

func (h *WebSocketHandler) handlePing() *protocol.Message {
	return h.successResponse("pong", map[string]interface{}{
		"timestamp": time.Now().Unix(),
	})
}

func (h *WebSocketHandler) successResponse(msgType string, data interface{}) *protocol.Message {
	dataJSON, _ := json.Marshal(data)
	return &protocol.Message{
		Type:      msgType,
		Timestamp: time.Now().Unix(),
		Data:      dataJSON,
	}
}

func (h *WebSocketHandler) errorResponse(message string) *protocol.Message {
	dataJSON, _ := json.Marshal(map[string]string{"error": message})
	return &protocol.Message{
		Type:      "error",
		Timestamp: time.Now().Unix(),
		Data:      dataJSON,
	}
}

func generateSessionID() string {
	return time.Now().Format("20060102150405") + "-" + randomString(8)
}

func randomString(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[time.Now().UnixNano()%int64(len(charset))]
	}
	return string(b)
}
