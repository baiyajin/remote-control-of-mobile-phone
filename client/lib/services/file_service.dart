import 'dart:async';
import 'dart:convert';
import 'device_service.dart';

class FileService {
  final DeviceService _deviceService;

  FileService(this._deviceService);

  // 获取文件列表（带响应等待）
  Future<List<FileInfo>> getFileList(String path) async {
    final completer = Completer<List<FileInfo>>();
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // 设置响应回调
    _deviceService.onFileListReceived = (data) {
      final responsePath = data['path'] as String?;
      if (responsePath == path) {
        final filesJson = data['files'] as List<dynamic>?;
        if (filesJson != null) {
          final files = filesJson
              .map((json) => FileInfo.fromJson(json as Map<String, dynamic>))
              .toList();
          completer.complete(files);
        } else {
          completer.complete([]);
        }
        _deviceService.onFileListReceived = null; // 清除回调
      }
    };
    
    final message = {
      'type': 'file_list',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'data': {
        'path': path,
      },
    };

    _deviceService.channel?.sink.add(jsonEncode(message));
    
    // 等待响应（超时5秒）
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _deviceService.onFileListReceived = null;
        return <FileInfo>[];
      },
    );
  }

  // 上传文件（带响应等待）
  Future<bool> uploadFile(String targetPath, String fileName, List<int> fileData) async {
    final completer = Completer<bool>();
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // 设置响应回调
    _deviceService.onFileUploadResponseReceived = (data) {
      final responsePath = data['path'] as String?;
      if (responsePath != null && responsePath.contains(fileName)) {
        final success = data['success'] as bool? ?? false;
        completer.complete(success);
        _deviceService.onFileUploadResponseReceived = null; // 清除回调
      }
    };
    
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
    
    // 等待响应（超时30秒）
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _deviceService.onFileUploadResponseReceived = null;
        return false;
      },
    );
  }

  // 下载文件（带响应等待）
  Future<List<int>?> downloadFile(String filePath) async {
    final completer = Completer<List<int>?>();
    
    // 设置响应回调
    _deviceService.onFileDownloadReceived = (data) {
      final responsePath = data['path'] as String?;
      if (responsePath == filePath) {
        final fileDataBase64 = data['file_data'] as String?;
        if (fileDataBase64 != null && fileDataBase64.isNotEmpty) {
          completer.complete(base64Decode(fileDataBase64));
        } else {
          completer.complete(null);
        }
        _deviceService.onFileDownloadReceived = null; // 清除回调
      }
    };
    
    final message = {
      'type': 'file_download',
      'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'data': {
        'path': filePath,
      },
    };

    _deviceService.channel?.sink.add(jsonEncode(message));
    
    // 等待响应（超时30秒）
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _deviceService.onFileDownloadReceived = null;
        return null;
      },
    );
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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'type': type,
      'size': size,
      'modified': modified,
    };
  }
}

