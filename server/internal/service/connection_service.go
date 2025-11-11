package service

import (
	"sync"
)

type Connection struct {
	DeviceID string
	Conn     interface{} // WebSocket connection
}

type ConnectionService struct {
	connections map[string]*Connection
	mu          sync.RWMutex
}

func NewConnectionService() *ConnectionService {
	return &ConnectionService{
		connections: make(map[string]*Connection),
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

