package service

import (
	"sync"
)

type Connection struct {
	DeviceID string
	Conn     interface{} // WebSocket connection
}

type Session struct {
	SessionID    string
	ControllerID string
	ControlledID string
}

type ConnectionService struct {
	connections map[string]*Connection
	sessions    map[string]*Session // sessionID -> Session
	mu          sync.RWMutex
}

func NewConnectionService() *ConnectionService {
	return &ConnectionService{
		connections: make(map[string]*Connection),
		sessions:    make(map[string]*Session),
	}
}

func (s *ConnectionService) AddConnection(deviceID string, conn interface{}) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.connections[deviceID] = &Connection{
		DeviceID: deviceID,
		Conn:     conn,
	}
}

func (s *ConnectionService) RemoveConnection(deviceID string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.connections, deviceID)
}

func (s *ConnectionService) GetConnection(deviceID string) (*Connection, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	conn, ok := s.connections[deviceID]
	return conn, ok
}

func (s *ConnectionService) GetConnectionCount() int {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return len(s.connections)
}

func (s *ConnectionService) GetAllConnections() map[string]*Connection {
	s.mu.RLock()
	defer s.mu.RUnlock()
	result := make(map[string]*Connection)
	for k, v := range s.connections {
		result[k] = v
	}
	return result
}

func (s *ConnectionService) CreateSession(sessionID, controllerID, controlledID string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.sessions[sessionID] = &Session{
		SessionID:    sessionID,
		ControllerID: controllerID,
		ControlledID: controlledID,
	}
}

func (s *ConnectionService) GetSession(sessionID string) (*Session, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	session, ok := s.sessions[sessionID]
	return session, ok
}

func (s *ConnectionService) RemoveSession(sessionID string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.sessions, sessionID)
}

func (s *ConnectionService) GetControllerID(controlledID string) string {
	s.mu.RLock()
	defer s.mu.RUnlock()
	for _, session := range s.sessions {
		if session.ControlledID == controlledID {
			return session.ControllerID
		}
	}
	return ""
}

func (s *ConnectionService) GetControlledID(controllerID string) string {
	s.mu.RLock()
	defer s.mu.RUnlock()
	for _, session := range s.sessions {
		if session.ControllerID == controllerID {
			return session.ControlledID
		}
	}
	return ""
}

// 获取控制端的所有会话（支持多设备同时控制）
func (s *ConnectionService) GetControllerSessions(controllerID string) []*Session {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var sessions []*Session
	for _, session := range s.sessions {
		if session.ControllerID == controllerID {
			sessions = append(sessions, session)
		}
	}
	return sessions
}

// 根据会话ID获取被控端ID
func (s *ConnectionService) GetControlledIDBySession(sessionID string) string {
	s.mu.RLock()
	defer s.mu.RUnlock()
	session, ok := s.sessions[sessionID]
	if !ok {
		return ""
	}
	return session.ControlledID
}

// 根据会话ID获取控制端ID
func (s *ConnectionService) GetControllerIDBySession(sessionID string) string {
	s.mu.RLock()
	defer s.mu.RUnlock()
	session, ok := s.sessions[sessionID]
	if !ok {
		return ""
	}
	return session.ControllerID
}

