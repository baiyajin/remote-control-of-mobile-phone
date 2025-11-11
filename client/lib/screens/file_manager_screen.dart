import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/device_service.dart';
import '../services/file_service.dart';
import '../models/device.dart';

class FileManagerScreen extends StatefulWidget {
  final Device device;

  const FileManagerScreen({super.key, required this.device});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  late FileService _fileService;
  List<FileInfo> _files = [];
  String _currentPath = 'C:\\';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fileService = FileService(Provider.of<DeviceService>(context, listen: false));
    _loadFiles(_currentPath);
  }


  Future<void> _loadFiles(String path) async {
    setState(() {
      _loading = true;
    });

    try {
      final files = await _fileService.getFileList(path);
      setState(() {
        _files = files;
        _currentPath = path;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载文件列表失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('文件管理: ${widget.device.name}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 路径栏
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    // 返回上一级目录
                    final parentPath = _currentPath.substring(0, _currentPath.lastIndexOf('\\'));
                    if (parentPath.isNotEmpty) {
                      _loadFiles(parentPath);
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: _currentPath),
                    decoration: const InputDecoration(
                      hintText: '路径',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (path) {
                      _loadFiles(path);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _loadFiles(_currentPath),
                ),
              ],
            ),
          ),
          // 文件列表
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _files.isEmpty
                    ? const Center(child: Text('暂无文件'))
                    : ListView.builder(
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          return ListTile(
                            leading: Icon(
                              file.type == 'directory'
                                  ? Icons.folder
                                  : Icons.insert_drive_file,
                              color: file.type == 'directory'
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            title: Text(file.name),
                            subtitle: Text(
                              file.type == 'directory'
                                  ? '文件夹'
                                  : '${(file.size / 1024).toStringAsFixed(2)} KB',
                            ),
                            onTap: () {
                              if (file.type == 'directory') {
                                _loadFiles(file.path);
                              }
                            },
                            trailing: file.type == 'file'
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.download),
                                        onPressed: () => _downloadFile(file),
                                        tooltip: '下载',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteFile(file),
                                        tooltip: '删除',
                                        color: Colors.red,
                                      ),
                                    ],
                                  )
                                : file.type == 'directory'
                                    ? IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _deleteFile(file),
                                        tooltip: '删除',
                                        color: Colors.red,
                                      )
                                    : null,
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadDialog(),
        child: const Icon(Icons.upload),
      ),
    );
  }

  void _showUploadDialog() async {
    // 选择文件
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    
    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;
      final file = File(filePath);
      
      try {
        final fileData = await file.readAsBytes();
        
        // 显示上传进度
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('正在上传: $fileName'),
                ],
              ),
            ),
          );
        }
        
        // 上传文件
        final success = await _fileService.uploadFile(_currentPath, fileName, fileData);
        
        if (mounted) {
          Navigator.pop(context); // 关闭进度对话框
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('文件上传成功')),
            );
            // 刷新文件列表
            _loadFiles(_currentPath);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('文件上传失败')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // 关闭进度对话框
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('文件上传失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _downloadFile(FileInfo file) async {
    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('正在下载: ${file.name}'),
              ],
            ),
          ),
        );
      }

      final fileData = await _fileService.downloadFile(file.path);
      
      if (mounted) {
        Navigator.pop(context); // 关闭进度对话框
        
        if (fileData != null) {
          // 保存文件 - file_picker 的 saveFile 只返回路径，需要手动写入
          final result = await FilePicker.platform.saveFile(
            fileName: file.name,
          );
          
          if (result != null) {
            try {
              final saveFile = File(result);
              await saveFile.writeAsBytes(fileData);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('文件下载成功')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('文件保存失败: $e')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('文件保存已取消')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文件下载失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 关闭进度对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文件下载失败: $e')),
        );
      }
    }
  }

  Future<void> _deleteFile(FileInfo file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${file.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _fileService.deleteFile(file.path);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('文件删除成功')),
            );
            // 刷新文件列表
            _loadFiles(_currentPath);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('文件删除失败')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('文件删除失败: $e')),
          );
        }
      }
    }
  }
}

