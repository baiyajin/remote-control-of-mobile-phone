package config

import (
	"encoding/json"
	"os"
	"sync"
)

type ConfigManager struct {
	config *Config
	mu     sync.RWMutex
}

var globalConfigManager *ConfigManager
var once sync.Once

func GetConfigManager() *ConfigManager {
	once.Do(func() {
		globalConfigManager = &ConfigManager{
			config: Load(),
		}
	})
	return globalConfigManager
}

func (cm *ConfigManager) GetConfig() *Config {
	cm.mu.RLock()
	defer cm.mu.RUnlock()
	return cm.config
}

func (cm *ConfigManager) UpdateConfig(newConfig *Config) error {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	cm.config = newConfig
	return cm.saveToFile()
}

func (cm *ConfigManager) saveToFile() error {
	// 保存配置到文件（可选）
	configFile := "config.json"
	data, err := json.MarshalIndent(cm.config, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(configFile, data, 0644)
}

