import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    GeneratedPluginRegistrant.register(with: self)
    
    // 注册自定义插件
    ScreenCapturePlugin.register(with: registrar(forPlugin: "ScreenCapturePlugin")!)
    InputControlPlugin.register(with: registrar(forPlugin: "InputControlPlugin")!)
  }
}
