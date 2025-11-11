import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/device_service.dart';
import '../services/input_control_service.dart';
import '../models/device.dart';

class RemoteControlScreen extends StatefulWidget {
  final Device device;

  const RemoteControlScreen({super.key, required this.device});

  @override
  State<RemoteControlScreen> createState() => _RemoteControlScreenState();
}

class _RemoteControlScreenState extends State<RemoteControlScreen> {
  final InputControlService _inputService = InputControlService();
  StreamSubscription<Uint8List>? _screenStream;
  ui.Image? _currentImage;
  bool _isControlling = false;

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

  @override
  void dispose() {
    _screenStream?.cancel();
    super.dispose();
  }

  Future<void> _connectToDevice() async {
    final deviceService = context.read<DeviceService>();
    await deviceService.connectToDevice(widget.device.id);
    
    // 开始接收屏幕流（这里简化处理，实际应该通过 WebSocket 接收）
    _startReceivingScreen();
  }

  void _startReceivingScreen() {
    // 这里应该通过 WebSocket 接收屏幕帧
    // 目前先使用本地屏幕捕获作为示例（被控端）
    if (mounted) {
      setState(() {
        _isControlling = true;
      });
    }
  }

  // 处理屏幕帧（通过 WebSocket 接收）
  Future<void> _handleScreenFrame(Uint8List frameData) async {
    try {
      final codec = await ui.instantiateImageCodec(frameData);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _currentImage = frame.image;
        });
      }
    } catch (e) {
      debugPrint('解析屏幕帧失败: $e');
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isControlling) return;
    
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    // 计算相对于屏幕显示区域的坐标
    final screenWidth = _currentImage?.width ?? 1920;
    final screenHeight = _currentImage?.height ?? 1080;
    final displayWidth = MediaQuery.of(context).size.width;
    final displayHeight = MediaQuery.of(context).size.height - 100; // 减去工具栏高度
    
    final scaleX = screenWidth / displayWidth;
    final scaleY = screenHeight / displayHeight;
    
    final screenX = localPosition.dx * scaleX;
    final screenY = localPosition.dy * scaleY;
    
    _inputService.moveMouse(screenX, screenY);
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isControlling) return;
    
    final renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    final screenWidth = _currentImage?.width ?? 1920;
    final screenHeight = _currentImage?.height ?? 1080;
    final displayWidth = MediaQuery.of(context).size.width;
    final displayHeight = MediaQuery.of(context).size.height - 100;
    
    final scaleX = screenWidth / displayWidth;
    final scaleY = screenHeight / displayHeight;
    
    final screenX = localPosition.dx * scaleX;
    final screenY = localPosition.dy * scaleY;
    
    _inputService.clickMouse(screenX, screenY, 'left');
  }

  void _onDoubleTap() {
    if (!_isControlling) return;
    // 双击处理
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('控制: ${widget.device.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _screenStream?.cancel();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(_isControlling ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _isControlling = !_isControlling;
              });
            },
            tooltip: _isControlling ? '暂停控制' : '继续控制',
          ),
        ],
      ),
      body: _currentImage == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在连接...'),
                ],
              ),
            )
          : GestureDetector(
              onPanUpdate: _onPanUpdate,
              onTapDown: _onTapDown,
              onDoubleTap: _onDoubleTap,
              child: Center(
                child: CustomPaint(
                  painter: ScreenPainter(_currentImage!),
                  size: Size.infinite,
                ),
              ),
            ),
      bottomNavigationBar: _isControlling
          ? Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard),
                    onPressed: () {
                      // 显示键盘输入对话框
                      _showKeyboardDialog();
                    },
                    tooltip: '键盘输入',
                  ),
                  IconButton(
                    icon: const Icon(Icons.file_copy),
                    onPressed: () {
                      // 文件管理
                    },
                    tooltip: '文件管理',
                  ),
                  IconButton(
                    icon: const Icon(Icons.terminal),
                    onPressed: () {
                      // 终端
                    },
                    tooltip: '终端',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  void _showKeyboardDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('键盘输入'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入文本',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              _inputService.typeText(textController.text);
              Navigator.pop(context);
            },
            child: const Text('发送'),
          ),
        ],
      ),
    );
  }
}

class ScreenPainter extends CustomPainter {
  final ui.Image image;

  ScreenPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    if (image.width == 0 || image.height == 0) return;

    // 计算缩放比例以适配屏幕
    final scaleX = size.width / image.width;
    final scaleY = size.height / image.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final scaledWidth = image.width * scale;
    final scaledHeight = image.height * scale;
    final offsetX = (size.width - scaledWidth) / 2;
    final offsetY = (size.height - scaledHeight) / 2;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(offsetX, offsetY, scaledWidth, scaledHeight),
      Paint(),
    );
  }

  @override
  bool shouldRepaint(ScreenPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}

