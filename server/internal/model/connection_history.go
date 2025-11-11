package model

import "time"

type ConnectionHistory struct {
	ID          string    `gorm:"primaryKey" json:"id"`
	ControllerID string `json:"controller_id"`
	ControlledID  string `json:"controlled_id"`
	StartTime   time.Time `json:"start_time"`
	EndTime     *time.Time `json:"end_time"`
	Duration    int       `json:"duration"` // seconds
	Status      string    `json:"status"`    // connected, disconnected, failed
}

func (ConnectionHistory) TableName() string {
	return "connection_history"
}

