import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/device_list_screen.dart';
import 'services/device_service.dart';
import 'services/screen_stream_service.dart';
import 'services/input_control_service.dart';
import 'services/file_operation_service.dart';
import 'services/terminal_execution_service.dart';
import 'widgets/notification_dialog.dart';

// 全局 navigator key，用于在非 widget 上下文中显示对话框
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final deviceService = DeviceService();
            final screenStreamService = ScreenStreamService();
            final inputControlService = InputControlService();
            final fileOperationService = FileOperationService();
            final terminalExecutionService = TerminalExecutionService();
            
            // 设置被控端逻辑（当收到连接请求时显示通知对话框）
            deviceService.onNotificationReceived = (data) async {
              final title = data['title'] as String? ?? '通知';
              final message = data['message'] as String? ?? '';
              final action = data['action'] as String?;
              
              // 使用全局 navigator key 显示通知对话框
              if (navigatorKey.currentContext != null) {
                final accepted = await NotificationDialog.show(
                  navigatorKey.currentContext!,
                  title: title,
                  message: message,
                  action: action,
                );
                
                if (accepted == true) {
                  // 用户接受连接，开始发送屏幕帧
                  final channel = deviceService.channel;
                  if (channel != null) {
                    await screenStreamService.startSendingScreen(channel);
                  }
                }
              } else {
                // 如果 context 不可用，自动接受（简化处理）
                if (action == 'accept') {
                  final channel = deviceService.channel;
                  if (channel != null) {
                    await screenStreamService.startSendingScreen(channel);
                  }
                }
              }
            };
            
            // 设置输入控制处理（被控端）
            deviceService.onInputControlReceived = (data) {
              final type = data['type'] as String;
              final inputData = data['data'] as Map<String, dynamic>;
              
              if (type == 'input_mouse') {
                final action = inputData['action'] as String;
                final x = inputData['x'] as double;
                final y = inputData['y'] as double;
                
                if (action == 'move') {
                  inputControlService.moveMouse(x, y);
                } else if (action == 'click') {
                  final button = inputData['button'] as String? ?? 'left';
                  inputControlService.clickMouse(x, y, button);
                } else if (action == 'scroll') {
                  final delta = inputData['delta'] as int? ?? 0;
                  inputControlService.scrollMouse(x, y, delta);
                }
              } else if (type == 'input_keyboard') {
                final action = inputData['action'] as String;
                final key = inputData['key'] as String;
                
                if (action == 'keypress') {
                  inputControlService.typeText(key);
                } else {
                  final modifiers = (inputData['modifiers'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList();
                  inputControlService.pressKey(key, modifiers: modifiers);
                }
              }
            };
            
            // 设置文件操作处理（被控端）
            deviceService.onFileListReceived = (data) async {
              final path = data['path'] as String? ?? 'C:\\';
              final files = await fileOperationService.getFileList(path);
              
              // 发送文件列表响应
              final message = {
                'type': 'file_list',
                'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                'data': {
                  'path': path,
                  'files': files.map((f) => f.toJson()).toList(),
                },
              };
              deviceService.channel?.sink.add(jsonEncode(message));
            };
            
            // 处理文件上传
            deviceService.onFileUploadReceived = (data) async {
              final targetPath = data['path'] as String? ?? 'C:\\';
              final fileName = data['file_name'] as String? ?? '';
              final fileDataBase64 = data['file_data'] as String? ?? '';
              
              if (fileDataBase64.isNotEmpty) {
                final fileData = base64Decode(fileDataBase64);
                final success = await fileOperationService.uploadFile(targetPath, fileName, fileData);
                
                // 发送上传结果
                final message = {
                  'type': 'file_upload_response',
                  'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  'data': {
                    'success': success,
                    'path': '$targetPath\\$fileName',
                  },
                };
                deviceService.channel?.sink.add(jsonEncode(message));
              }
            };
            
            // 处理文件下载
            deviceService.onFileDownloadReceived = (data) async {
              final filePath = data['path'] as String? ?? '';
              if (filePath.isNotEmpty) {
                final fileData = await fileOperationService.downloadFile(filePath);
                
                // 发送文件数据
                final message = {
                  'type': 'file_download',
                  'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  'data': {
                    'path': filePath,
                    'file_data': fileData != null ? base64Encode(fileData) : '',
                  },
                };
                deviceService.channel?.sink.add(jsonEncode(message));
              }
            };
            
            // 处理文件删除
            deviceService.onFileDeleteReceived = (data) async {
              final filePath = data['path'] as String? ?? '';
              if (filePath.isNotEmpty) {
                final success = await fileOperationService.deleteFile(filePath);
                
                // 发送删除结果
                final message = {
                  'type': 'file_delete_response',
                  'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  'data': {
                    'success': success,
                    'path': filePath,
                  },
                };
                deviceService.channel?.sink.add(jsonEncode(message));
              }
            };
            
            // 设置终端命令处理（被控端）
            deviceService.onTerminalCommandReceived = (data) async {
              final command = data['command'] as String? ?? '';
              final workingDir = data['working_dir'] as String?;
              
              if (command.isNotEmpty) {
                final result = await terminalExecutionService.executeCommand(command, workingDir: workingDir);
                
                // 发送终端输出
                final message = {
                  'type': 'terminal_output',
                  'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  'data': result,
                };
                deviceService.channel?.sink.add(jsonEncode(message));
              }
            };
            
            return deviceService;
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: '远程控制',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const DeviceListScreen(),
      ),
    );
  }
}
