#include "input_control_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_linux.h>
#include <flutter/standard_method_codec.h>

#include <memory>

class InputControlPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarLinux *registrar);

  InputControlPlugin();

  virtual ~InputControlPlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

// static
void InputControlPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarLinux *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "input_control",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<InputControlPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

InputControlPlugin::InputControlPlugin() {}

InputControlPlugin::~InputControlPlugin() {}

void InputControlPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("moveMouse") == 0 ||
      method_call.method_name().compare("clickMouse") == 0 ||
      method_call.method_name().compare("pressKey") == 0 ||
      method_call.method_name().compare("typeText") == 0) {
    // Linux 输入控制待实现
    result->NotImplemented();
  } else {
    result->NotImplemented();
  }
}

void RegisterInputControlPlugin(flutter::PluginRegistrarLinux *registrar) {
  InputControlPlugin::RegisterWithRegistrar(registrar);
}

