import 'dart:convert';
import 'device_service.dart';

class FileService {
  final DeviceService _deviceService;

  FileService(this._deviceService);

  // 获取文件列表
  Future<List<FileInfo>> getFileList(String path) async {
    final message = {
      'type': 'file_list',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'data': {
        'path': path,
      },
    };

    _deviceService.channel?.sink.add(jsonEncode(message));
    
    // 这里应该等待响应，简化处理
    return [];
  }

  // 上传文件
  Future<void> uploadFile(String targetPath, String fileName, List<int> fileData) async {
    final message = {
      'type': 'file_upload',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'data': {
        'path': targetPath,
        'file_name': fileName,
        'file_data': base64Encode(fileData),
      },
    };

    _deviceService.channel?.sink.add(jsonEncode(message));
  }

  // 下载文件
  Future<List<int>?> downloadFile(String filePath) async {
    final message = {
      'type': 'file_download',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'data': {
        'path': filePath,
      },
    };

    _deviceService.channel?.sink.add(jsonEncode(message));
    
    // 这里应该等待响应，简化处理
    return null;
  }

  // 删除文件
  Future<void> deleteFile(String filePath) async {
    final message = {
      'type': 'file_delete',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'data': {
        'path': filePath,
      },
    };

    _deviceService.channel?.sink.add(jsonEncode(message));
  }
}

class FileInfo {
  final String name;
  final String path;
  final String type; // file, directory
  final int size;
  final int modified;

  FileInfo({
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.modified,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      name: json['name'] as String,
      path: json['path'] as String,
      type: json['type'] as String,
      size: json['size'] as int,
      modified: json['modified'] as int,
    );
  }
}

