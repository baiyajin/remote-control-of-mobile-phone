import Flutter
import AppKit

public class ScreenCapturePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "screen_capture", binaryMessenger: registrar.messenger())
    let instance = ScreenCapturePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getScreenSize":
      if let screen = NSScreen.main {
        let size = screen.frame.size
        result([
          "width": Int(size.width),
          "height": Int(size.height)
        ])
      } else {
        result(FlutterError(code: "NO_SCREEN", message: "无法获取屏幕", details: nil))
      }
    case "captureScreen":
      // macOS 屏幕捕获实现
      result(FlutterError(code: "NOT_IMPLEMENTED", message: "macOS屏幕捕获待实现", details: nil))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

