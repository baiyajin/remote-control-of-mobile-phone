package service

import (
	"remote-control/server/internal/model"
	"time"

	"gorm.io/gorm"
)

type DeviceService struct {
	db *gorm.DB
}

func NewDeviceService(db *gorm.DB) *DeviceService {
	return &DeviceService{db: db}
}

func (s *DeviceService) RegisterDevice(device *model.Device) error {
	device.LastSeen = time.Now()
	if device.CreatedAt.IsZero() {
		device.CreatedAt = time.Now()
	}
	return s.db.Save(device).Error
}

func (s *DeviceService) GetDeviceList() ([]model.Device, error) {
	var devices []model.Device
	err := s.db.Find(&devices).Error
	return devices, err
}

func (s *DeviceService) GetDeviceByID(id string) (*model.Device, error) {
	var device model.Device
	err := s.db.Where("id = ?", id).First(&device).Error
	if err != nil {
		return nil, err
	}
	return &device, nil
}

func (s *DeviceService) UpdateLastSeen(deviceID string) error {
	return s.db.Model(&model.Device{}).
		Where("id = ?", deviceID).
		Update("last_seen", time.Now()).Error
}

func (s *DeviceService) DeleteDevice(deviceID string) error {
	return s.db.Delete(&model.Device{}, "id = ?", deviceID).Error
}

