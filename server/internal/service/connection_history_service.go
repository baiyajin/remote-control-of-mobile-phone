package service

import (
	"remote-control/server/internal/model"
	"time"

	"gorm.io/gorm"
)

type ConnectionHistoryService struct {
	db *gorm.DB
}

func NewConnectionHistoryService(db *gorm.DB) *ConnectionHistoryService {
	return &ConnectionHistoryService{db: db}
}

func (s *ConnectionHistoryService) CreateHistory(controllerID, controlledID string) (*model.ConnectionHistory, error) {
	history := &model.ConnectionHistory{
		ID:          generateHistoryID(),
		ControllerID: controllerID,
		ControlledID:  controlledID,
		StartTime:   time.Now(),
		Status:      "connected",
	}
	return history, s.db.Create(history).Error
}

func (s *ConnectionHistoryService) EndHistory(historyID string) error {
	now := time.Now()
	history := &model.ConnectionHistory{}
	if err := s.db.Where("id = ?", historyID).First(history).Error; err != nil {
		return err
	}

	duration := int(now.Sub(history.StartTime).Seconds())
	return s.db.Model(history).Updates(map[string]interface{}{
		"end_time": &now,
		"duration": duration,
		"status":   "disconnected",
	}).Error
}

func (s *ConnectionHistoryService) GetHistoryList(limit int) ([]model.ConnectionHistory, error) {
	var histories []model.ConnectionHistory
	query := s.db.Order("start_time DESC")
	if limit > 0 {
		query = query.Limit(limit)
	}
	err := query.Find(&histories).Error
	return histories, err
}

func (s *ConnectionHistoryService) GetHistoryByDevice(deviceID string, limit int) ([]model.ConnectionHistory, error) {
	var histories []model.ConnectionHistory
	query := s.db.Where("controller_id = ? OR controlled_id = ?", deviceID, deviceID).
		Order("start_time DESC")
	if limit > 0 {
		query = query.Limit(limit)
	}
	err := query.Find(&histories).Error
	return histories, err
}

func generateHistoryID() string {
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

