import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class InputControlService {
  static const MethodChannel _channel = MethodChannel('input_control');

  // 鼠标移动
  Future<void> moveMouse(double x, double y) async {
    try {
      await _channel.invokeMethod('moveMouse', {
        'x': x,
        'y': y,
      });
    } catch (e) {
      debugPrint('鼠标移动失败: $e');
    }
  }

  // 鼠标点击
  Future<void> clickMouse(double x, double y, String button) async {
    try {
      await _channel.invokeMethod('clickMouse', {
        'x': x,
        'y': y,
        'button': button, // left, right, middle
      });
    } catch (e) {
      debugPrint('鼠标点击失败: $e');
    }
  }

  // 鼠标滚轮
  Future<void> scrollMouse(double x, double y, int delta) async {
    try {
      await _channel.invokeMethod('scrollMouse', {
        'x': x,
        'y': y,
        'delta': delta,
      });
    } catch (e) {
      debugPrint('鼠标滚轮失败: $e');
    }
  }

  // 键盘按键
  Future<void> pressKey(String key, {List<String>? modifiers}) async {
    try {
      await _channel.invokeMethod('pressKey', {
        'key': key,
        'modifiers': modifiers ?? [],
      });
    } catch (e) {
      debugPrint('键盘按键失败: $e');
    }
  }

  // 键盘输入文本
  Future<void> typeText(String text) async {
    try {
      await _channel.invokeMethod('typeText', {
        'text': text,
      });
    } catch (e) {
      debugPrint('输入文本失败: $e');
    }
  }
}

