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
                                ? IconButton(
                                    icon: const Icon(Icons.download),
                                    onPressed: () {
                                      // 下载文件
                                      _fileService.downloadFile(file.path);
                                    },
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
}

