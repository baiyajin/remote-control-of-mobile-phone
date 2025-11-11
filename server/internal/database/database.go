package database

import (
	"remote-control/server/internal/model"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func Init(dbPath string) (*gorm.DB, error) {
	db, err := gorm.Open(sqlite.Open(dbPath), &gorm.Config{})
	if err != nil {
		return nil, err
	}

	// 自动迁移
	err = db.AutoMigrate(
		&model.Device{},
		&model.ConnectionHistory{},
	)
	if err != nil {
		return nil, err
	}

	return db, nil
}

