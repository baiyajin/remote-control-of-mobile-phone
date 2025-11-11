import Flutter
import UIKit
import ReplayKit

public class ScreenCapturePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "screen_capture", binaryMessenger: registrar.messenger())
    let instance = ScreenCapturePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getScreenSize":
      let screenSize = UIScreen.main.bounds.size
      result([
        "width": Int(screenSize.width * UIScreen.main.scale),
        "height": Int(screenSize.height * UIScreen.main.scale)
      ])
    case "captureScreen":
      // iOS 屏幕捕获需要使用 ReplayKit，需要用户授权
      result(FlutterError(code: "NOT_IMPLEMENTED", message: "iOS屏幕捕获需要ReplayKit授权", details: nil))
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

