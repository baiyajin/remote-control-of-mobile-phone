import Flutter
import UIKit

public class InputControlPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "input_control", binaryMessenger: registrar.messenger())
    let instance = InputControlPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "moveMouse":
      // iOS 不支持鼠标，使用触摸事件
      result(nil)
    case "clickMouse":
      // iOS 触摸事件
      result(nil)
    case "pressKey":
      // iOS 键盘输入
      result(nil)
    case "typeText":
      // iOS 文本输入
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

