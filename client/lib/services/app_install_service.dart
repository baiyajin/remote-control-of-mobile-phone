import 'package:flutter/services.dart';

class AppInstallService {
  static const MethodChannel _channel = MethodChannel('app_install');

  // 安装应用
  Future<bool> installApp(List<int> apkData, String fileName) async {
    try {
      final result = await _channel.invokeMethod<bool>('installApp', {
        'apkData': apkData,
        'fileName': fileName,
      });
      return result ?? false;
    } catch (e) {
      print('安装应用失败: $e');
      return false;
    }
  }

  // 检查安装权限
  Future<bool> checkInstallPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkInstallPermission');
      return result ?? false;
    } catch (e) {
      print('检查安装权限失败: $e');
      return false;
    }
  }
}

