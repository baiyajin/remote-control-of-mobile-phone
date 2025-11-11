#include "screen_capture_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_linux.h>
#include <flutter/standard_method_codec.h>

#include <memory>

class ScreenCapturePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarLinux *registrar);

  ScreenCapturePlugin();

  virtual ~ScreenCapturePlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

// static
void ScreenCapturePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarLinux *registrar) {
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

ScreenCapturePlugin::ScreenCapturePlugin() {}

ScreenCapturePlugin::~ScreenCapturePlugin() {}

void ScreenCapturePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getScreenSize") == 0) {
    // Linux 屏幕尺寸获取
    result->NotImplemented();
  } else if (method_call.method_name().compare("captureScreen") == 0) {
    // Linux 屏幕捕获
    result->NotImplemented();
  } else {
    result->NotImplemented();
  }
}

void RegisterScreenCapturePlugin(flutter::PluginRegistrarLinux *registrar) {
  ScreenCapturePlugin::RegisterWithRegistrar(registrar);
}

