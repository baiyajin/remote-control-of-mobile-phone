import 'dart:convert';
import 'device_service.dart';

class TerminalService {
  final DeviceService _deviceService;
  Function(String)? onOutputReceived;
  Function(String)? onErrorReceived;

  TerminalService(this._deviceService);

  // 执行命令
  Future<void> executeCommand(String command, {String? workingDir}) async {
    final message = {
      'type': 'terminal_command',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'data': {
        'command': command,
        if (workingDir != null) 'working_dir': workingDir,
      },
    };

    _deviceService.channel?.sink.add(jsonEncode(message));
  }

  // 处理终端输出
  void handleTerminalOutput(Map<String, dynamic> data) {
    final stdout = data['stdout'] as String?;
    final stderr = data['stderr'] as String?;
    final exitCode = data['exit_code'] as int?;

    if (stdout != null && stdout.isNotEmpty) {
      onOutputReceived?.call(stdout);
    }
    if (stderr != null && stderr.isNotEmpty) {
      onErrorReceived?.call(stderr);
    }
  }
}

