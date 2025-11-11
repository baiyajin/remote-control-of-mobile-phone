import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class TerminalExecutionService {
  static const MethodChannel _channel = MethodChannel('terminal');

  // 执行命令
  Future<Map<String, dynamic>> executeCommand(String command, {String? workingDir}) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('executeCommand', {
        'command': command,
        if (workingDir != null) 'workingDir': workingDir,
      });
      
      if (result != null) {
        return {
          'stdout': result['stdout'] as String? ?? '',
          'stderr': result['stderr'] as String? ?? '',
          'exit_code': result['exit_code'] as int? ?? -1,
        };
      }
      return {
        'stdout': '',
        'stderr': '执行失败',
        'exit_code': -1,
      };
    } catch (e) {
      debugPrint('执行命令失败: $e');
      return {
        'stdout': '',
        'stderr': e.toString(),
        'exit_code': -1,
      };
    }
  }
}

