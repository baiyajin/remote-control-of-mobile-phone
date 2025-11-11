#include "terminal_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <process.h>
#include <memory>
#include <string>
#include <sstream>

class TerminalPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  TerminalPlugin();

  virtual ~TerminalPlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  flutter::EncodableValue ExecuteCommand(const std::string& command, const std::string& workingDir);
};

void TerminalPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "terminal",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<TerminalPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

TerminalPlugin::TerminalPlugin() {}

TerminalPlugin::~TerminalPlugin() {}

void TerminalPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());

  if (method_call.method_name().compare("executeCommand") == 0) {
    if (args && args->find(flutter::EncodableValue("command")) != args->end()) {
      std::string command = std::get<std::string>(args->at(flutter::EncodableValue("command")));
      std::string workingDir = "";
      if (args->find(flutter::EncodableValue("workingDir")) != args->end()) {
        workingDir = std::get<std::string>(args->at(flutter::EncodableValue("workingDir")));
      }
      auto output = ExecuteCommand(command, workingDir);
      result->Success(output);
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments");
    }
  } else {
    result->NotImplemented();
  }
}

flutter::EncodableValue TerminalPlugin::ExecuteCommand(const std::string& command, const std::string& workingDir) {
  flutter::EncodableMap result;
  std::string stdout_str;
  std::string stderr_str;
  int exitCode = -1;

  HANDLE hChildStd_OUT_Rd = NULL;
  HANDLE hChildStd_OUT_Wr = NULL;
  HANDLE hChildStd_ERR_Rd = NULL;
  HANDLE hChildStd_ERR_Wr = NULL;

  SECURITY_ATTRIBUTES saAttr;
  saAttr.nLength = sizeof(SECURITY_ATTRIBUTES);
  saAttr.bInheritHandle = TRUE;
  saAttr.lpSecurityDescriptor = NULL;

  // 创建管道
  if (!CreatePipe(&hChildStd_OUT_Rd, &hChildStd_OUT_Wr, &saAttr, 0)) {
    result[flutter::EncodableValue("stdout")] = flutter::EncodableValue("");
    result[flutter::EncodableValue("stderr")] = flutter::EncodableValue("创建管道失败");
    result[flutter::EncodableValue("exit_code")] = flutter::EncodableValue(-1);
    return flutter::EncodableValue(result);
  }

  if (!CreatePipe(&hChildStd_ERR_Rd, &hChildStd_ERR_Wr, &saAttr, 0)) {
    CloseHandle(hChildStd_OUT_Rd);
    CloseHandle(hChildStd_OUT_Wr);
    result[flutter::EncodableValue("stdout")] = flutter::EncodableValue("");
    result[flutter::EncodableValue("stderr")] = flutter::EncodableValue("创建管道失败");
    result[flutter::EncodableValue("exit_code")] = flutter::EncodableValue(-1);
    return flutter::EncodableValue(result);
  }

  // 设置管道句柄不可继承
  SetHandleInformation(hChildStd_OUT_Rd, HANDLE_FLAG_INHERIT, 0);
  SetHandleInformation(hChildStd_ERR_Rd, HANDLE_FLAG_INHERIT, 0);

  PROCESS_INFORMATION piProcInfo;
  STARTUPINFOA siStartInfo;
  ZeroMemory(&piProcInfo, sizeof(PROCESS_INFORMATION));
  ZeroMemory(&siStartInfo, sizeof(STARTUPINFOA));
  siStartInfo.cb = sizeof(STARTUPINFOA);
  siStartInfo.hStdError = hChildStd_ERR_Wr;
  siStartInfo.hStdOutput = hChildStd_OUT_Wr;
  siStartInfo.dwFlags |= STARTF_USESTDHANDLES;

  // 构建命令（使用 cmd /c）
  std::string fullCommand = "cmd /c \"" + command + "\"";

  // 创建进程
  BOOL bSuccess = CreateProcessA(
      NULL,
      const_cast<char*>(fullCommand.c_str()),
      NULL,
      NULL,
      TRUE,
      0,
      NULL,
      workingDir.empty() ? NULL : workingDir.c_str(),
      &siStartInfo,
      &piProcInfo);

  if (!bSuccess) {
    CloseHandle(hChildStd_OUT_Rd);
    CloseHandle(hChildStd_OUT_Wr);
    CloseHandle(hChildStd_ERR_Rd);
    CloseHandle(hChildStd_ERR_Wr);
    result[flutter::EncodableValue("stdout")] = flutter::EncodableValue("");
    result[flutter::EncodableValue("stderr")] = flutter::EncodableValue("创建进程失败");
    result[flutter::EncodableValue("exit_code")] = flutter::EncodableValue(-1);
    return flutter::EncodableValue(result);
  }

  // 关闭写入端
  CloseHandle(hChildStd_OUT_Wr);
  CloseHandle(hChildStd_ERR_Wr);

  // 读取输出
  DWORD dwRead;
  CHAR chBuf[4096];
  BOOL bSuccessRead = FALSE;

  // 读取 stdout
  for (;;) {
    bSuccessRead = ReadFile(hChildStd_OUT_Rd, chBuf, 4096, &dwRead, NULL);
    if (!bSuccessRead || dwRead == 0) break;
    stdout_str.append(chBuf, dwRead);
  }

  // 读取 stderr
  for (;;) {
    bSuccessRead = ReadFile(hChildStd_ERR_Rd, chBuf, 4096, &dwRead, NULL);
    if (!bSuccessRead || dwRead == 0) break;
    stderr_str.append(chBuf, dwRead);
  }

  // 等待进程结束
  WaitForSingleObject(piProcInfo.hProcess, INFINITE);
  DWORD dwExitCode;
  GetExitCodeProcess(piProcInfo.hProcess, &dwExitCode);
  exitCode = static_cast<int>(dwExitCode);

  // 清理
  CloseHandle(piProcInfo.hProcess);
  CloseHandle(piProcInfo.hThread);
  CloseHandle(hChildStd_OUT_Rd);
  CloseHandle(hChildStd_ERR_Rd);

  result[flutter::EncodableValue("stdout")] = flutter::EncodableValue(stdout_str);
  result[flutter::EncodableValue("stderr")] = flutter::EncodableValue(stderr_str);
  result[flutter::EncodableValue("exit_code")] = flutter::EncodableValue(exitCode);

  return flutter::EncodableValue(result);
}

void RegisterTerminalPlugin(flutter::PluginRegistrarWindows *registrar) {
  TerminalPlugin::RegisterWithRegistrar(registrar);
}

