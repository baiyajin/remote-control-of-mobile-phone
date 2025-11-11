#include "screen_capture_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <gdiplus.h>
#include <memory>
#include <sstream>
#include <vector>

#pragma comment(lib, "gdiplus.lib")

using namespace Gdiplus;

class ScreenCapturePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  ScreenCapturePlugin();

  virtual ~ScreenCapturePlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::vector<uint8_t> CaptureScreen();
  std::pair<int, int> GetScreenSize();
};

// static
void ScreenCapturePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "screen_capture",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<ScreenCapturePlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

static ULONG_PTR g_gdiplusToken = 0;

ScreenCapturePlugin::ScreenCapturePlugin() {
  if (g_gdiplusToken == 0) {
    GdiplusStartupInput gdiplusStartupInput;
    GdiplusStartup(&g_gdiplusToken, &gdiplusStartupInput, NULL);
  }
}

ScreenCapturePlugin::~ScreenCapturePlugin() {
  // GDI+ 在程序结束时清理
}

void ScreenCapturePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getScreenSize") == 0) {
    auto size = GetScreenSize();
    flutter::EncodableMap response;
    response[flutter::EncodableValue("width")] = flutter::EncodableValue(size.first);
    response[flutter::EncodableValue("height")] = flutter::EncodableValue(size.second);
    result->Success(flutter::EncodableValue(response));
  } else if (method_call.method_name().compare("captureFrame") == 0) {
    auto frame = CaptureScreen();
    result->Success(flutter::EncodableValue(frame));
  } else {
    result->NotImplemented();
  }
}

std::pair<int, int> ScreenCapturePlugin::GetScreenSize() {
  int width = GetSystemMetrics(SM_CXSCREEN);
  int height = GetSystemMetrics(SM_CYSCREEN);
  return std::make_pair(width, height);
}

std::vector<uint8_t> ScreenCapturePlugin::CaptureScreen() {
  int screenWidth = GetSystemMetrics(SM_CXSCREEN);
  int screenHeight = GetSystemMetrics(SM_CYSCREEN);

  HDC hScreenDC = GetDC(NULL);
  HDC hMemoryDC = CreateCompatibleDC(hScreenDC);

  HBITMAP hBitmap = CreateCompatibleBitmap(hScreenDC, screenWidth, screenHeight);
  HBITMAP hOldBitmap = (HBITMAP)SelectObject(hMemoryDC, hBitmap);

  BitBlt(hMemoryDC, 0, 0, screenWidth, screenHeight, hScreenDC, 0, 0, SRCCOPY);

  hBitmap = (HBITMAP)SelectObject(hMemoryDC, hOldBitmap);

  // Convert to PNG using GDI+
  IStream* stream = NULL;
  CreateStreamOnHGlobal(NULL, TRUE, &stream);

  Bitmap bitmap(hBitmap, NULL);
  CLSID clsid;
  CLSIDFromString(L"{557CF406-1A04-11D3-9A73-0000F81EF32E}", &clsid); // PNG
  Status status = bitmap.Save(stream, &clsid);

  std::vector<uint8_t> buffer;
  if (status == Ok && stream != NULL) {
    // Read stream to vector
    STATSTG stat;
    if (stream->Stat(&stat, STATFLAG_NONAME) == S_OK) {
      ULONG size = stat.cbSize.LowPart;
      buffer.resize(size);
      LARGE_INTEGER li = {0};
      stream->Seek(li, STREAM_SEEK_SET, NULL);
      ULONG read = 0;
      stream->Read(buffer.data(), size, &read);
    }
    stream->Release();
  }

  DeleteObject(hBitmap);
  DeleteDC(hMemoryDC);
  ReleaseDC(NULL, hScreenDC);

  return buffer;
}

void RegisterScreenCapturePlugin(flutter::PluginRegistrarWindows *registrar) {
  ScreenCapturePlugin::RegisterWithRegistrar(registrar);
}

