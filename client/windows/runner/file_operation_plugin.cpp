#include "file_operation_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <filesystem>
#include <fstream>
#include <memory>
#include <vector>

namespace fs = std::filesystem;

class FileOperationPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FileOperationPlugin();

  virtual ~FileOperationPlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::EncodableValue GetFileList(const std::string& path);
  bool UploadFile(const std::string& targetPath, const std::string& fileName, const std::vector<uint8_t>& fileData);
  std::vector<uint8_t> DownloadFile(const std::string& filePath);
      bool DeleteFile(const std::string& filePath);
      bool RenameFile(const std::string& oldPath, const std::string& newPath);
      bool MoveFile(const std::string& sourcePath, const std::string& targetPath);
      bool CreateDirectory(const std::string& path);
    };

void FileOperationPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "file_operation",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<FileOperationPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

FileOperationPlugin::FileOperationPlugin() {}

FileOperationPlugin::~FileOperationPlugin() {}

void FileOperationPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());

  if (method_call.method_name().compare("getFileList") == 0) {
    if (args && args->find(flutter::EncodableValue("path")) != args->end()) {
      std::string path = std::get<std::string>(args->at(flutter::EncodableValue("path")));
      auto fileList = GetFileList(path);
      result->Success(fileList);
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments");
    }
  } else if (method_call.method_name().compare("uploadFile") == 0) {
    if (args && args->find(flutter::EncodableValue("targetPath")) != args->end() &&
        args->find(flutter::EncodableValue("fileName")) != args->end() &&
        args->find(flutter::EncodableValue("fileData")) != args->end()) {
      std::string targetPath = std::get<std::string>(args->at(flutter::EncodableValue("targetPath")));
      std::string fileName = std::get<std::string>(args->at(flutter::EncodableValue("fileName")));
      auto fileDataList = std::get<flutter::EncodableList>(args->at(flutter::EncodableValue("fileData")));
      std::vector<uint8_t> fileData;
      for (const auto& item : fileDataList) {
        fileData.push_back(std::get<uint8_t>(item));
      }
      bool success = UploadFile(targetPath, fileName, fileData);
      result->Success(flutter::EncodableValue(success));
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments");
    }
  } else if (method_call.method_name().compare("downloadFile") == 0) {
    if (args && args->find(flutter::EncodableValue("filePath")) != args->end()) {
      std::string filePath = std::get<std::string>(args->at(flutter::EncodableValue("filePath")));
      auto fileData = DownloadFile(filePath);
      flutter::EncodableList resultList;
      for (uint8_t byte : fileData) {
        resultList.push_back(flutter::EncodableValue(byte));
      }
      result->Success(flutter::EncodableValue(resultList));
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments");
    }
  } else if (method_call.method_name().compare("deleteFile") == 0) {
    if (args && args->find(flutter::EncodableValue("filePath")) != args->end()) {
      std::string filePath = std::get<std::string>(args->at(flutter::EncodableValue("filePath")));
      bool success = DeleteFile(filePath);
      result->Success(flutter::EncodableValue(success));
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments");
    }
  } else if (method_call.method_name().compare("renameFile") == 0) {
    if (args && args->find(flutter::EncodableValue("oldPath")) != args->end() &&
        args->find(flutter::EncodableValue("newPath")) != args->end()) {
      std::string oldPath = std::get<std::string>(args->at(flutter::EncodableValue("oldPath")));
      std::string newPath = std::get<std::string>(args->at(flutter::EncodableValue("newPath")));
      bool success = RenameFile(oldPath, newPath);
      result->Success(flutter::EncodableValue(success));
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments");
    }
  } else if (method_call.method_name().compare("moveFile") == 0) {
    if (args && args->find(flutter::EncodableValue("sourcePath")) != args->end() &&
        args->find(flutter::EncodableValue("targetPath")) != args->end()) {
      std::string sourcePath = std::get<std::string>(args->at(flutter::EncodableValue("sourcePath")));
      std::string targetPath = std::get<std::string>(args->at(flutter::EncodableValue("targetPath")));
      bool success = MoveFile(sourcePath, targetPath);
      result->Success(flutter::EncodableValue(success));
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments");
    }
  } else if (method_call.method_name().compare("createDirectory") == 0) {
    if (args && args->find(flutter::EncodableValue("path")) != args->end()) {
      std::string path = std::get<std::string>(args->at(flutter::EncodableValue("path")));
      bool success = CreateDirectory(path);
      result->Success(flutter::EncodableValue(success));
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments");
    }
  } else {
    result->NotImplemented();
  }
}

flutter::EncodableValue FileOperationPlugin::GetFileList(const std::string& path) {
  flutter::EncodableList fileList;
  
  try {
    if (!fs::exists(path) || !fs::is_directory(path)) {
      return flutter::EncodableValue(fileList);
    }

    for (const auto& entry : fs::directory_iterator(path)) {
      flutter::EncodableMap fileInfo;
      fileInfo[flutter::EncodableValue("name")] = flutter::EncodableValue(entry.path().filename().string());
      fileInfo[flutter::EncodableValue("path")] = flutter::EncodableValue(entry.path().string());
      
      if (entry.is_directory()) {
        fileInfo[flutter::EncodableValue("type")] = flutter::EncodableValue("directory");
        fileInfo[flutter::EncodableValue("size")] = flutter::EncodableValue(0);
      } else {
        fileInfo[flutter::EncodableValue("type")] = flutter::EncodableValue("file");
        fileInfo[flutter::EncodableValue("size")] = flutter::EncodableValue(static_cast<int64_t>(fs::file_size(entry.path())));
      }
      
      auto ftime = fs::last_write_time(entry.path());
      auto sctp = std::chrono::time_point_cast<std::chrono::system_clock::duration>(
          ftime - fs::file_time_type::clock::now() + std::chrono::system_clock::now());
      auto timeT = std::chrono::system_clock::to_time_t(sctp);
      fileInfo[flutter::EncodableValue("modified")] = flutter::EncodableValue(static_cast<int64_t>(timeT));
      
      fileList.push_back(flutter::EncodableValue(fileInfo));
    }
  } catch (const std::exception& e) {
    // 错误处理
  }

  return flutter::EncodableValue(fileList);
}

bool FileOperationPlugin::UploadFile(const std::string& targetPath, const std::string& fileName, const std::vector<uint8_t>& fileData) {
  try {
    fs::path fullPath = fs::path(targetPath) / fileName;
    std::ofstream file(fullPath, std::ios::binary);
    if (file.is_open()) {
      file.write(reinterpret_cast<const char*>(fileData.data()), fileData.size());
      file.close();
      return true;
    }
  } catch (const std::exception& e) {
    return false;
  }
  return false;
}

std::vector<uint8_t> FileOperationPlugin::DownloadFile(const std::string& filePath) {
  std::vector<uint8_t> fileData;
  try {
    if (fs::exists(filePath) && fs::is_regular_file(filePath)) {
      std::ifstream file(filePath, std::ios::binary);
      if (file.is_open()) {
        file.seekg(0, std::ios::end);
        size_t size = file.tellg();
        file.seekg(0, std::ios::beg);
        fileData.resize(size);
        file.read(reinterpret_cast<char*>(fileData.data()), size);
        file.close();
      }
    }
  } catch (const std::exception& e) {
    // 错误处理
  }
  return fileData;
}

bool FileOperationPlugin::DeleteFile(const std::string& filePath) {
  try {
    if (fs::exists(filePath)) {
      if (fs::is_directory(filePath)) {
        fs::remove_all(filePath);
      } else {
        fs::remove(filePath);
      }
      return true;
    }
  } catch (const std::exception& e) {
    return false;
  }
  return false;
}

bool FileOperationPlugin::RenameFile(const std::string& oldPath, const std::string& newPath) {
  try {
    if (fs::exists(oldPath)) {
      fs::rename(oldPath, newPath);
      return true;
    }
  } catch (const std::exception& e) {
    return false;
  }
  return false;
}

bool FileOperationPlugin::MoveFile(const std::string& sourcePath, const std::string& targetPath) {
  try {
    if (fs::exists(sourcePath)) {
      fs::rename(sourcePath, targetPath);
      return true;
    }
  } catch (const std::exception& e) {
    return false;
  }
  return false;
}

bool FileOperationPlugin::CreateDirectory(const std::string& path) {
  try {
    if (!fs::exists(path)) {
      fs::create_directories(path);
      return true;
    }
  } catch (const std::exception& e) {
    return false;
  }
  return false;
}

void RegisterFileOperationPlugin(flutter::PluginRegistrarWindows *registrar) {
  FileOperationPlugin::RegisterWithRegistrar(registrar);
}

