package model

import "time"

type Device struct {
	ID          string    `gorm:"primaryKey" json:"id"`
	Name        string    `gorm:"not null" json:"name"`
	Type        string    `gorm:"not null" json:"type"` // windows, android, ios, macos, linux
	IPAddress   string    `json:"ip_address"`
	LastSeen    time.Time `json:"last_seen"`
	Capabilities string   `json:"capabilities"` // JSON array
	CreatedAt   time.Time `json:"created_at"`
}

func (Device) TableName() string {
	return "devices"
}

