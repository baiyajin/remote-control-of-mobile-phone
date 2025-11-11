import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/device_list_screen.dart';
import 'services/device_service.dart';
import 'services/screen_stream_service.dart';
import 'services/input_control_service.dart';

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
            
            // 设置被控端逻辑（当收到连接请求时开始发送屏幕帧）
            deviceService.onNotificationReceived = (data) async {
              final action = data['action'] as String?;
              if (action == 'accept') {
                // 开始发送屏幕帧
                final channel = deviceService.channel;
                if (channel != null) {
                  await screenStreamService.startSendingScreen(channel);
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
            
            return deviceService;
          },
        ),
      ],
      child: MaterialApp(
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
