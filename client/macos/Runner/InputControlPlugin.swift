import Flutter
import AppKit

public class InputControlPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "input_control", binaryMessenger: registrar.messenger())
    let instance = InputControlPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "moveMouse":
      // macOS 鼠标移动
      result(nil)
    case "clickMouse":
      // macOS 鼠标点击
      result(nil)
    case "pressKey":
      // macOS 键盘输入
      result(nil)
    case "typeText":
      // macOS 文本输入
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

