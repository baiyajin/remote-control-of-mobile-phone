import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'file_service.dart';

class FileOperationService {
  static const MethodChannel _channel = MethodChannel('file_operation');

  // 获取文件列表
  Future<List<FileInfo>> getFileList(String path) async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getFileList', {
        'path': path,
      });
      
      if (result != null) {
        return result.map((json) => FileInfo.fromJson(Map<String, dynamic>.from(json))).toList();
      }
      return [];
    } catch (e) {
      debugPrint('获取文件列表失败: $e');
      return [];
    }
  }

  // 上传文件
  Future<bool> uploadFile(String targetPath, String fileName, Uint8List fileData) async {
    try {
      final result = await _channel.invokeMethod<bool>('uploadFile', {
        'targetPath': targetPath,
        'fileName': fileName,
        'fileData': fileData.toList(),
      });
      return result ?? false;
    } catch (e) {
      debugPrint('上传文件失败: $e');
      return false;
    }
  }

  // 下载文件
  Future<Uint8List?> downloadFile(String filePath) async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('downloadFile', {
        'filePath': filePath,
      });
      
      if (result != null) {
        return Uint8List.fromList(result.map((e) => e as int).toList());
      }
      return null;
    } catch (e) {
      debugPrint('下载文件失败: $e');
      return null;
    }
  }

  // 删除文件
  Future<bool> deleteFile(String filePath) async {
    try {
      final result = await _channel.invokeMethod<bool>('deleteFile', {
        'filePath': filePath,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('删除文件失败: $e');
      return false;
    }
  }

  // 重命名文件
  Future<bool> renameFile(String oldPath, String newPath) async {
    try {
      final result = await _channel.invokeMethod<bool>('renameFile', {
        'oldPath': oldPath,
        'newPath': newPath,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('重命名文件失败: $e');
      return false;
    }
  }

  // 移动文件
  Future<bool> moveFile(String sourcePath, String targetPath) async {
    try {
      final result = await _channel.invokeMethod<bool>('moveFile', {
        'sourcePath': sourcePath,
        'targetPath': targetPath,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('移动文件失败: $e');
      return false;
    }
  }

  // 创建文件夹
  Future<bool> createDirectory(String path) async {
    try {
      final result = await _channel.invokeMethod<bool>('createDirectory', {
        'path': path,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('创建文件夹失败: $e');
      return false;
    }
  }
}

