import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/connection_history.dart';

class ConnectionHistoryScreen extends StatefulWidget {
  const ConnectionHistoryScreen({super.key});

  @override
  State<ConnectionHistoryScreen> createState() => _ConnectionHistoryScreenState();
}

class _ConnectionHistoryScreenState extends State<ConnectionHistoryScreen> {
  List<ConnectionHistory> _histories = [];
  bool _loading = false;
  String _serverUrl = 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/api/connection/history?limit=50'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final historiesJson = data['histories'] as List<dynamic>;
        setState(() {
          _histories = historiesJson
              .map((json) => ConnectionHistory.fromJson(json as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('加载连接历史失败')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载连接历史失败: $e')),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}秒';
    } else if (seconds < 3600) {
      return '${seconds ~/ 60}分钟';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}小时${minutes}分钟';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('连接历史'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _histories.isEmpty
              ? const Center(child: Text('暂无连接历史'))
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    itemCount: _histories.length,
                    itemBuilder: (context, index) {
                      final history = _histories[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: Icon(
                            history.status == 'connected'
                                ? Icons.check_circle
                                : history.status == 'disconnected'
                                    ? Icons.cancel
                                    : Icons.error,
                            color: history.status == 'connected'
                                ? Colors.green
                                : history.status == 'disconnected'
                                    ? Colors.grey
                                    : Colors.red,
                          ),
                          title: Text('${history.controllerId} -> ${history.controlledId}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('开始时间: ${history.startTime.toString().substring(0, 19)}'),
                              if (history.endTime != null)
                                Text('结束时间: ${history.endTime.toString().substring(0, 19)}'),
                              Text('持续时间: ${_formatDuration(history.duration)}'),
                              Text('状态: ${history.status}'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

