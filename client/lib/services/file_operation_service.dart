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
}

