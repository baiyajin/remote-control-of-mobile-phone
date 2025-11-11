package com.example.client

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // 注册屏幕捕获插件
        flutterEngine.plugins.add(ScreenCapturePlugin(this))
        
        // 注册输入控制插件
        flutterEngine.plugins.add(InputControlPlugin(this))
        
        // 注册应用安装插件
        flutterEngine.plugins.add(AppInstallPlugin(this))
    }
}
