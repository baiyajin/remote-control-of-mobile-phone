import Flutter
import AppKit
import CoreGraphics
import Quartz

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
      captureScreen(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func captureScreen(result: @escaping FlutterResult) {
    // 使用 CGDisplayCreateImage 捕获主屏幕
    if let screen = NSScreen.main {
      let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
      
      if let imageRef = CGDisplayCreateImage(displayID) {
        let bitmapRep = NSBitmapImageRep(cgImage: imageRef)
        if let imageData = bitmapRep.representation(using: .png, properties: [:]) {
          result(FlutterStandardTypedData(bytes: imageData))
        } else {
          result(FlutterError(code: "CAPTURE_FAILED", message: "无法生成图像数据", details: nil))
        }
      } else {
        result(FlutterError(code: "CAPTURE_FAILED", message: "无法捕获屏幕", details: nil))
      }
    } else {
      result(FlutterError(code: "NO_SCREEN", message: "无法获取屏幕", details: nil))
    }
  }
}

