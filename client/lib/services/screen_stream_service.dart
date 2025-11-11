import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'screen_capture_service.dart';

class ScreenStreamService {
  final ScreenCaptureService _screenService = ScreenCaptureService();
  WebSocketChannel? _channel;
  Timer? _captureTimer;
  bool _isStreaming = false;
  int _fps = 15; // 默认15帧/秒

  // 屏幕帧流（用于被控端发送）
  StreamController<Uint8List>? _frameStreamController;

  // 接收屏幕帧的回调
  Function(Uint8List)? onFrameReceived;

  bool get isStreaming => _isStreaming;

  // 开始发送屏幕流（被控端）
  Future<void> startSendingScreen(WebSocketChannel channel) async {
    if (_isStreaming) return;

    _channel = channel;
    _isStreaming = true;

    // 获取屏幕尺寸
    final screenSize = await _screenService.getScreenSize();
    if (screenSize == null) {
      debugPrint('无法获取屏幕尺寸');
      return;
    }

    // 开始周期性捕获
    _captureTimer = Timer.periodic(
      Duration(milliseconds: 1000 ~/ _fps),
      (timer) async {
        if (!_isStreaming) {
          timer.cancel();
          return;
        }

        final frame = await _screenService.captureFrame();
        if (frame != null && _channel != null) {
          // 发送屏幕帧
          final message = {
            'type': 'screen_frame',
            'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'data': {
              'frame_data': base64Encode(frame),
              'width': screenSize['width'],
              'height': screenSize['height'],
            },
          };
          _channel!.sink.add(jsonEncode(message));
        }
      },
    );
  }

  // 停止发送屏幕流
  void stopSendingScreen() {
    _isStreaming = false;
    _captureTimer?.cancel();
    _captureTimer = null;
  }

  // 处理接收到的屏幕帧（控制端）
  void handleScreenFrame(Map<String, dynamic> data) {
    try {
      final frameDataBase64 = data['frame_data'] as String;
      final frameData = base64Decode(frameDataBase64);
      onFrameReceived?.call(frameData);
    } catch (e) {
      debugPrint('处理屏幕帧失败: $e');
    }
  }

  // 设置帧率
  void setFps(int fps) {
    _fps = fps.clamp(1, 30); // 限制在1-30fps
  }

  void dispose() {
    stopSendingScreen();
    _frameStreamController?.close();
  }
}

