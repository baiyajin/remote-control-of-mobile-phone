import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/device_service.dart';
import '../services/terminal_service.dart';
import '../models/device.dart';

class TerminalScreen extends StatefulWidget {
  final Device device;

  const TerminalScreen({super.key, required this.device});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  late TerminalService _terminalService;
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<String> _outputLines = [];
  final List<String> _commandHistory = [];
  int _historyIndex = -1;
  String _currentDir = 'C:\\';

  @override
  void initState() {
    super.initState();
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    _terminalService = TerminalService(deviceService);
    
    // 设置输出接收回调
    _terminalService.onOutputReceived = (output) {
      setState(() {
        _outputLines.addAll(output.split('\n'));
      });
      _scrollToBottom();
    };
    
    _terminalService.onErrorReceived = (error) {
      setState(() {
        _outputLines.addAll(['[ERROR]', ...error.split('\n')]);
      });
      _scrollToBottom();
    };
    
    // 设置终端输出处理回调
    deviceService.onTerminalOutputReceived = (data) {
      _terminalService.handleTerminalOutput(data);
    };
  }

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    deviceService.onTerminalOutputReceived = null;
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _executeCommand() {
    final command = _commandController.text.trim();
    if (command.isEmpty) return;

    // 添加到历史记录
    if (_commandHistory.isEmpty || _commandHistory.last != command) {
      _commandHistory.add(command);
      if (_commandHistory.length > 100) {
        _commandHistory.removeAt(0);
      }
    }
    _historyIndex = _commandHistory.length;

    setState(() {
      _outputLines.add('$_currentDir> $command');
    });
    _commandController.clear();
    _scrollToBottom();

    _terminalService.executeCommand(command, workingDir: _currentDir);
  }
  
  void _navigateHistory(int direction) {
    if (_commandHistory.isEmpty) return;
    
    setState(() {
      _historyIndex = (_historyIndex + direction).clamp(0, _commandHistory.length);
      if (_historyIndex < _commandHistory.length) {
        _commandController.text = _commandHistory[_historyIndex];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('终端: ${widget.device.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 输出区域
          Expanded(
            child: Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _outputLines.length,
                itemBuilder: (context, index) {
                  final line = _outputLines[index];
                  final isError = line.startsWith('[ERROR]');
                  return Text(
                    line,
                    style: TextStyle(
                      color: isError ? Colors.red : Colors.green,
                      fontFamily: 'Courier',
                      fontSize: 14,
                    ),
                  );
                },
              ),
            ),
          ),
          // 输入区域
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Text(
                  '$_currentDir> ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    style: const TextStyle(fontFamily: 'Courier'),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '输入命令... (↑↓ 浏览历史)',
                    ),
                    onSubmitted: (_) => _executeCommand(),
                    onTap: () {
                      _historyIndex = _commandHistory.length;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: () => _navigateHistory(-1),
                  tooltip: '上一条命令',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: () => _navigateHistory(1),
                  tooltip: '下一条命令',
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _executeCommand,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

