import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/device.dart';

class DeviceService extends ChangeNotifier {
  WebSocketChannel? _channel;
  List<Device> _devices = [];
  String? _currentDeviceId;
  bool _connected = false;

  List<Device> get devices => _devices;
  bool get connected => _connected;
  String? get currentDeviceId => _currentDeviceId;
  WebSocketChannel? get channel => _channel;

  // 服务器地址（可以从配置读取）
  String _serverUrl = 'ws://localhost:8080/ws';

  void setServerUrl(String url) {
    _serverUrl = url;
  }

  Future<void> connect() async {
    if (_connected && _channel != null) {
      return;
    }

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      _connected = true;
      notifyListeners();

      // 监听消息
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          print('WebSocket 错误: $error');
          _connected = false;
          notifyListeners();
        },
        onDone: () {
          print('WebSocket 连接关闭');
          _connected = false;
          _currentSessionId = null;
          notifyListeners();
          // 自动重连（仅在非手动断开时）
          if (_channel != null) {
            _autoReconnect();
          }
        },
      );

      // 注册当前设备
      await registerDevice();
      _reconnectAttempts = 0; // 重置重连计数
    } catch (e) {
      print('连接失败: $e');
      _connected = false;
      notifyListeners();
      // 连接失败也尝试重连
      _autoReconnect();
    }
  }

  Future<void> registerDevice() async {
    if (!_connected) return;

    // 生成设备ID（实际应该从本地存储读取或生成）
    final deviceId = _currentDeviceId ?? 'device-${DateTime.now().millisecondsSinceEpoch}';
    _currentDeviceId = deviceId;

    final message = {
      'type': 'device_register',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'data': {
        'device_id': deviceId,
        'device_name': 'Flutter-Client',
        'device_type': _getPlatformType(),
        'ip_address': '',
        'capabilities': ['screen', 'input', 'file', 'terminal'],
      },
    };

    _channel?.sink.add(jsonEncode(message));
  }

  Future<void> requestDeviceList() async {
    if (!_connected) return;

    final message = {
      'type': 'device_list',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'data': {},
    };

    _channel?.sink.add(jsonEncode(message));
  }

  // 屏幕帧接收回调
  Function(Map<String, dynamic>)? onScreenFrameReceived;
  // 连接响应回调
  Function(Map<String, dynamic>)? onConnectResponse;
  // 通知接收回调
  Function(Map<String, dynamic>)? onNotificationReceived;
  // 输入控制接收回调（被控端）
  Function(Map<String, dynamic>)? onInputControlReceived;
  // 终端输出接收回调
  Function(Map<String, dynamic>)? onTerminalOutputReceived;
  // 文件列表接收回调
  Function(Map<String, dynamic>)? onFileListReceived;
  // 文件上传接收回调
  Function(Map<String, dynamic>)? onFileUploadReceived;
  // 文件下载接收回调
  Function(Map<String, dynamic>)? onFileDownloadReceived;
  // 文件删除接收回调
  Function(Map<String, dynamic>)? onFileDeleteReceived;
  // 终端命令接收回调
  Function(Map<String, dynamic>)? onTerminalCommandReceived;
  // 文件上传响应接收回调
  Function(Map<String, dynamic>)? onFileUploadResponseReceived;
  // 文件删除响应接收回调
  Function(Map<String, dynamic>)? onFileDeleteResponseReceived;
  // 应用安装响应接收回调
  Function(Map<String, dynamic>)? onAppInstallResponseReceived;
  
  // 当前会话ID
  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());
      final type = data['type'] as String;

      switch (type) {
        case 'device_list':
          _handleDeviceList(data['data']);
          break;
        case 'device_register_response':
          print('设备注册成功');
          // 注册成功后请求设备列表
          requestDeviceList();
          break;
        case 'connect_response':
          final responseData = data['data'] as Map<String, dynamic>;
          _currentSessionId = responseData['session_id'] as String?;
          onConnectResponse?.call(responseData);
          break;
        case 'screen_frame':
          onScreenFrameReceived?.call(data['data'] as Map<String, dynamic>);
          break;
        case 'notification':
          onNotificationReceived?.call(data['data'] as Map<String, dynamic>);
          break;
        case 'input_mouse':
        case 'input_keyboard':
          onInputControlReceived?.call(data);
          break;
        case 'terminal_output':
          onTerminalOutputReceived?.call(data['data'] as Map<String, dynamic>);
          break;
        case 'file_list':
          onFileListReceived?.call(data['data'] as Map<String, dynamic>);
          break;
        case 'file_upload':
          onFileUploadReceived?.call(data['data'] as Map<String, dynamic>);
          break;
        case 'file_download':
          onFileDownloadReceived?.call(data['data'] as Map<String, dynamic>);
          break;
        case 'file_delete':
          onFileDeleteReceived?.call(data['data'] as Map<String, dynamic>);
          break;
        case 'terminal_command':
          onTerminalCommandReceived?.call(data['data'] as Map<String, dynamic>);
          break;
        case 'file_upload_response':
          onFileUploadResponseReceived?.call(data['data'] as Map<String, dynamic>);
          break;
        case 'file_delete_response':
          onFileDeleteResponseReceived?.call(data['data'] as Map<String, dynamic>);
          break;
        case 'app_install_response':
          onAppInstallResponseReceived?.call(data['data'] as Map<String, dynamic>);
          break;
        default:
          print('未知消息类型: $type');
      }
    } catch (e) {
      print('处理消息失败: $e');
    }
  }

  void _handleDeviceList(Map<String, dynamic> data) {
    final devicesJson = data['devices'] as List<dynamic>;
    _devices = devicesJson
        .map((json) => Device.fromJson(json as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> connectToDevice(String deviceId) async {
    if (!_connected) return;

    final message = {
      'type': 'connect_request',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'data': {
        'device_id': deviceId,
      },
    };

    _channel?.sink.add(jsonEncode(message));
  }

  // 发送输入控制消息
  void sendMouseInput(String action, double x, double y, {String? button, int? delta}) {
    if (!_connected) return;

    final message = {
      'type': 'input_mouse',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      if (_currentSessionId != null) 'session_id': _currentSessionId,
      'data': {
        'action': action,
        'x': x,
        'y': y,
        if (button != null) 'button': button,
        if (delta != null) 'delta': delta,
      },
    };

    _channel?.sink.add(jsonEncode(message));
  }

  void sendKeyboardInput(String action, String key, {List<String>? modifiers}) {
    if (!_connected) return;

    final message = {
      'type': 'input_keyboard',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      if (_currentSessionId != null) 'session_id': _currentSessionId,
      'data': {
        'action': action,
        'key': key,
        if (modifiers != null) 'modifiers': modifiers,
      },
    };

    _channel?.sink.add(jsonEncode(message));
  }
  
  // 发送文件操作消息（带 SessionID）
  void sendFileOperation(String type, Map<String, dynamic> data) {
    if (!_connected) return;
    
    final message = {
      'type': type,
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      if (_currentSessionId != null) 'session_id': _currentSessionId,
      'data': data,
    };
    
    _channel?.sink.add(jsonEncode(message));
  }
  
  // 发送终端命令（带 SessionID）
  void sendTerminalCommand(String command, {String? workingDir}) {
    if (!_connected) return;
    
    final message = {
      'type': 'terminal_command',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      if (_currentSessionId != null) 'session_id': _currentSessionId,
      'data': {
        'command': command,
        if (workingDir != null) 'working_dir': workingDir,
      },
    };
    
    _channel?.sink.add(jsonEncode(message));
  }

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  void _autoReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('达到最大重连次数，停止重连');
      return;
    }
    
    _reconnectAttempts++;
    _reconnectTimer = Timer(_reconnectDelay, () {
      print('尝试重连 ($_reconnectAttempts/$_maxReconnectAttempts)...');
      connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _channel?.sink.close();
    _channel = null;
    _connected = false;
    _currentSessionId = null;
    notifyListeners();
  }

  String _getPlatformType() {
    if (kIsWeb) {
      return 'web';
    }
    if (Platform.isWindows) {
      return 'windows';
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    if (Platform.isMacOS) {
      return 'macos';
    }
    if (Platform.isLinux) {
      return 'linux';
    }
    return 'unknown';
  }
}

