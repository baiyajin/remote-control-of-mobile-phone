import Flutter
import AppKit
import CoreGraphics

public class InputControlPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "input_control", binaryMessenger: registrar.messenger())
    let instance = InputControlPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "moveMouse":
      if let args = call.arguments as? [String: Any],
         let x = args["x"] as? Double,
         let y = args["y"] as? Double {
        moveMouse(x: x, y: y)
      }
      result(nil)
    case "clickMouse":
      if let args = call.arguments as? [String: Any],
         let x = args["x"] as? Double,
         let y = args["y"] as? Double,
         let button = args["button"] as? String {
        clickMouse(x: x, y: y, button: button)
      }
      result(nil)
    case "pressKey":
      if let args = call.arguments as? [String: Any],
         let key = args["key"] as? String {
        pressKey(key: key)
      }
      result(nil)
    case "typeText":
      if let args = call.arguments as? [String: Any],
         let text = args["text"] as? String {
        typeText(text: text)
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func moveMouse(x: Double, y: Double) {
    let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, cursorPosition: CGPoint(x: x, y: y), mouseButton: .left)
    event?.post(tap: .cghidEventTap)
  }
  
  private func clickMouse(x: Double, y: Double, button: String) {
    let mouseButton: CGMouseButton = (button == "right") ? .right : .left
    let mouseTypeDown: CGEventType = (button == "right") ? .rightMouseDown : .leftMouseDown
    let mouseTypeUp: CGEventType = (button == "right") ? .rightMouseUp : .leftMouseUp
    
    let downEvent = CGEvent(mouseEventSource: nil, mouseType: mouseTypeDown, cursorPosition: CGPoint(x: x, y: y), mouseButton: mouseButton)
    let upEvent = CGEvent(mouseEventSource: nil, mouseType: mouseTypeUp, cursorPosition: CGPoint(x: x, y: y), mouseButton: mouseButton)
    
    downEvent?.post(tap: .cghidEventTap)
    upEvent?.post(tap: .cghidEventTap)
  }
  
  private func pressKey(key: String) {
    // 将字符串键转换为虚拟键码
    let keyCode = getKeyCode(key: key)
    if keyCode != 0 {
      let downEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
      let upEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
      downEvent?.post(tap: .cghidEventTap)
      upEvent?.post(tap: .cghidEventTap)
    }
  }
  
  private func typeText(text: String) {
    // 使用 CGEvent 输入文本
    for char in text {
      let keyCode = getKeyCode(key: String(char))
      if keyCode != 0 {
        let downEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        let upEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        downEvent?.post(tap: .cghidEventTap)
        upEvent?.post(tap: .cghidEventTap)
      }
    }
  }
  
  private func getKeyCode(key: String) -> CGKeyCode {
    // 简单的键码映射
    switch key.lowercased() {
    case "enter", "return": return 36
    case "space": return 49
    case "tab": return 48
    case "escape": return 53
    case "backspace": return 51
    default:
      // 对于字母和数字，使用 ASCII 码
      if key.count == 1 {
        let char = key.uppercased().first!
        if char >= "A" && char <= "Z" {
          return CGKeyCode(char.asciiValue! - 65) // A = 0
        }
        if char >= "0" && char <= "9" {
          return CGKeyCode(char.asciiValue! - 18) // 0 = 29
        }
      }
      return 0
    }
  }
}

