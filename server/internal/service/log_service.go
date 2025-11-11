package service

import (
	"sync"
	"time"
)

type LogEntry struct {
	Timestamp time.Time `json:"timestamp"`
	Level     string    `json:"level"` // info, warning, error
	Message   string    `json:"message"`
}

type LogService struct {
	logs []LogEntry
	mu   sync.RWMutex
	maxLogs int
}

func NewLogService(maxLogs int) *LogService {
	if maxLogs <= 0 {
		maxLogs = 1000 // 默认保存1000条日志
	}
	return &LogService{
		logs: make([]LogEntry, 0),
		maxLogs: maxLogs,
	}
}

func (s *LogService) AddLog(level, message string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	entry := LogEntry{
		Timestamp: time.Now(),
		Level:     level,
		Message:   message,
	}

	s.logs = append(s.logs, entry)

	// 限制日志数量
	if len(s.logs) > s.maxLogs {
		s.logs = s.logs[len(s.logs)-s.maxLogs:]
	}
}

func (s *LogService) GetLogs(limit int) []LogEntry {
	s.mu.RLock()
	defer s.mu.RUnlock()

	if limit <= 0 || limit > len(s.logs) {
		limit = len(s.logs)
	}

	// 返回最近的日志
	start := len(s.logs) - limit
	if start < 0 {
		start = 0
	}

	result := make([]LogEntry, limit)
	copy(result, s.logs[start:])
	return result
}

func (s *LogService) ClearLogs() {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.logs = make([]LogEntry, 0)
}

