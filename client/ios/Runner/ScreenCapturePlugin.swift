import Flutter
import UIKit
import ReplayKit

public class ScreenCapturePlugin: NSObject, FlutterPlugin {
  private var rpScreenRecorder: RPScreenRecorder?
  
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
      captureScreen(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  private func captureScreen(result: @escaping FlutterResult) {
    // 方法1: 使用 UIGraphicsImageRenderer 捕获当前窗口
    if let window = UIApplication.shared.windows.first {
      let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
      let image = renderer.image { context in
        window.layer.render(in: context.cgContext)
      }
      
      if let imageData = image.pngData() {
        result(FlutterStandardTypedData(bytes: imageData))
      } else {
        result(FlutterError(code: "CAPTURE_FAILED", message: "无法生成图像数据", details: nil))
      }
    } else {
      // 方法2: 使用 RPScreenRecorder（需要权限）
      rpScreenRecorder = RPScreenRecorder.shared()
      rpScreenRecorder?.isMicrophoneEnabled = false
      rpScreenRecorder?.isCameraEnabled = false
      
      rpScreenRecorder?.startCapture(handler: { sampleBuffer, bufferType, error in
        if error != nil {
          result(FlutterError(code: "CAPTURE_ERROR", message: error?.localizedDescription, details: nil))
          return
        }
        
        if bufferType == .video {
          if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            let context = CIContext()
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
              let uiImage = UIImage(cgImage: cgImage)
              if let imageData = uiImage.pngData() {
                result(FlutterStandardTypedData(bytes: imageData))
                self.rpScreenRecorder?.stopCapture { error in
                  if let error = error {
                    print("停止捕获失败: \(error)")
                  }
                }
              }
            }
          }
        }
      }, completionHandler: { error in
        if let error = error {
          result(FlutterError(code: "CAPTURE_ERROR", message: error.localizedDescription, details: nil))
        }
      })
    }
  }
}

