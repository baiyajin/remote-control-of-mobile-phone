import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/device_service.dart';
import '../models/device.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  @override
  void initState() {
    super.initState();
    // 延迟连接，确保服务已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceService>().connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('远程控制'),
        actions: [
          Consumer<DeviceService>(
            builder: (context, service, _) {
              return IconButton(
                icon: Icon(service.connected ? Icons.cloud_done : Icons.cloud_off),
                onPressed: () {
                  if (service.connected) {
                    service.disconnect();
                  } else {
                    service.connect();
                  }
                },
                tooltip: service.connected ? '已连接' : '未连接',
              );
            },
          ),
        ],
      ),
      body: Consumer<DeviceService>(
        builder: (context, service, _) {
          if (!service.connected) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在连接服务器...'),
                ],
              ),
            );
          }

          if (service.devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.devices, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无设备'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      service.requestDeviceList();
                    },
                    child: const Text('刷新设备列表'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              service.requestDeviceList();
            },
            child: ListView.builder(
              itemCount: service.devices.length,
              itemBuilder: (context, index) {
                final device = service.devices[index];
                return _DeviceCard(device: device, service: service);
              },
            ),
          );
        },
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final Device device;
  final DeviceService service;

  const _DeviceCard({required this.device, required this.service});

  String _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'windows':
        return '🖥️';
      case 'android':
        return '📱';
      case 'ios':
        return '📱';
      case 'macos':
        return '💻';
      case 'linux':
        return '🐧';
      default:
        return '💻';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Text(
          _getDeviceIcon(device.type),
          style: const TextStyle(fontSize: 32),
        ),
        title: Text(device.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('类型: ${device.type}'),
            if (device.ipAddress != null) Text('IP: ${device.ipAddress}'),
            Text(
              device.online ? '在线' : '离线',
              style: TextStyle(
                color: device.online ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
        trailing: device.online
            ? ElevatedButton(
                onPressed: () {
                  service.connectToDevice(device.id);
                  // TODO: 导航到远程控制界面
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('正在连接 ${device.name}...')),
                  );
                },
                child: const Text('连接'),
              )
            : const Text('离线', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}

