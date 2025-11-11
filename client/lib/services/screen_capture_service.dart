import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenCaptureService {
  static const MethodChannel _channel = MethodChannel('screen_capture');

  // 开始屏幕捕获
  Future<void> startCapture() async {
    try {
      await _channel.invokeMethod('startCapture');
    } catch (e) {
      debugPrint('启动屏幕捕获失败: $e');
    }
  }

  // 停止屏幕捕获
  Future<void> stopCapture() async {
    try {
      await _channel.invokeMethod('stopCapture');
    } catch (e) {
      debugPrint('停止屏幕捕获失败: $e');
    }
  }

  // 捕获一帧屏幕
  Future<Uint8List?> captureFrame() async {
    try {
      // 尝试 captureScreen 方法（Android）
      final result = await _channel.invokeMethod<Uint8List>('captureScreen');
      return result;
    } catch (e) {
      try {
        // 回退到 captureFrame 方法（Windows）
        final result = await _channel.invokeMethod<Uint8List>('captureFrame');
        return result;
      } catch (e2) {
        debugPrint('捕获屏幕帧失败: $e2');
        return null;
      }
    }
  }

  // 获取屏幕尺寸
  Future<Map<String, int>?> getScreenSize() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('getScreenSize');
      if (result != null) {
        return {
          'width': result['width'] as int,
          'height': result['height'] as int,
        };
      }
      return null;
    } catch (e) {
      debugPrint('获取屏幕尺寸失败: $e');
      return null;
    }
  }

  // 开始周期性捕获（用于被控端）
  Stream<Uint8List>? startPeriodicCapture({int fps = 15}) {
    final controller = StreamController<Uint8List>();
    Timer? timer;

    timer = Timer.periodic(Duration(milliseconds: 1000 ~/ fps), (timer) async {
      final frame = await captureFrame();
      if (frame != null) {
        controller.add(frame);
      }
    });

    // 清理定时器
    controller.onCancel = () {
      timer?.cancel();
    };

    return controller.stream;
  }
}

