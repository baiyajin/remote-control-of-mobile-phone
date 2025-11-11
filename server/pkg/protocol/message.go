package protocol

import "encoding/json"

// Message 通用消息结构
type Message struct {
	Type      string          `json:"type"`
	Timestamp int64           `json:"timestamp"`
	Data      json.RawMessage `json:"data"`
	SessionID string          `json:"session_id,omitempty"` // 会话ID，用于多设备同时控制
}

// DeviceRegisterData 设备注册数据
type DeviceRegisterData struct {
	DeviceID    string   `json:"device_id"`
	DeviceName  string   `json:"device_name"`
	DeviceType  string   `json:"device_type"` // windows, android, ios, macos, linux
	IPAddress   string   `json:"ip_address"`
	Capabilities []string `json:"capabilities"`
}

// DeviceListData 设备列表数据
type DeviceListData struct {
	Devices []DeviceInfo `json:"devices"`
}

// DeviceInfo 设备信息
type DeviceInfo struct {
	ID          string   `json:"id"`
	Name        string   `json:"name"`
	Type        string   `json:"type"`
	IPAddress   string   `json:"ip_address"`
	LastSeen    int64    `json:"last_seen"`
	Capabilities []string `json:"capabilities"`
	Online      bool     `json:"online"`
}

// ConnectRequestData 连接请求数据
type ConnectRequestData struct {
	DeviceID  string `json:"device_id"`
	AuthToken string `json:"auth_token,omitempty"`
}

// ConnectResponseData 连接响应数据
type ConnectResponseData struct {
	Status    string `json:"status"` // success, failed
	SessionID string `json:"session_id,omitempty"`
	Message   string `json:"message,omitempty"`
}

// ScreenFrameData 屏幕帧数据
type ScreenFrameData struct {
	FrameData string `json:"frame_data"` // base64 encoded
	Timestamp int64  `json:"timestamp"`
	Width     int    `json:"width"`
	Height    int    `json:"height"`
}

// InputMouseData 鼠标输入数据
type InputMouseData struct {
	Action string  `json:"action"` // move, click, scroll
	X      float64 `json:"x"`
	Y      float64 `json:"y"`
	Button string  `json:"button,omitempty"` // left, right, middle
	Delta  int     `json:"delta,omitempty"`   // for scroll
}

// InputKeyboardData 键盘输入数据
type InputKeyboardData struct {
	Action    string   `json:"action"` // keydown, keyup, keypress
	Key       string   `json:"key"`
	Modifiers []string `json:"modifiers,omitempty"` // ctrl, shift, alt
}

// FileListData 文件列表数据
type FileListData struct {
	Path  string     `json:"path"`
	Files []FileInfo `json:"files"`
}

// FileInfo 文件信息
type FileInfo struct {
	Name     string `json:"name"`
	Path     string `json:"path"`
	Type     string `json:"type"` // file, directory
	Size     int64  `json:"size"`
	Modified int64  `json:"modified"`
}

// TerminalCommandData 终端命令数据
type TerminalCommandData struct {
	Command    string `json:"command"`
	WorkingDir string `json:"working_dir,omitempty"`
}

// TerminalOutputData 终端输出数据
type TerminalOutputData struct {
	Stdout   string `json:"stdout"`
	Stderr   string `json:"stderr"`
	ExitCode int    `json:"exit_code"`
}

// NotificationData 通知数据
type NotificationData struct {
	Title  string `json:"title"`
	Message string `json:"message"`
	Action string `json:"action,omitempty"` // accept, reject
}

// AppInstallData 应用安装数据
type AppInstallData struct {
	APKData  string `json:"apk_data"`  // base64 encoded APK file
	FileName string `json:"file_name"`
}

// AppInstallResponseData 应用安装响应数据
type AppInstallResponseData struct {
	Success bool   `json:"success"`
	Message string `json:"message,omitempty"`
}

