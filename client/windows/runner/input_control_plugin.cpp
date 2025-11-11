#include "input_control_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <windows.h>
#include <memory>

class InputControlPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  InputControlPlugin();

  virtual ~InputControlPlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void MoveMouse(double x, double y);
  void ClickMouse(double x, double y, const std::string& button);
  void ScrollMouse(double x, double y, int delta);
  void PressKey(const std::string& key, const std::vector<std::string>& modifiers);
  void TypeText(const std::string& text);
};

// static
void InputControlPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
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
  const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
  
  if (method_call.method_name().compare("moveMouse") == 0) {
    if (args && args->find(flutter::EncodableValue("x")) != args->end() &&
        args->find(flutter::EncodableValue("y")) != args->end()) {
      double x = std::get<double>(args->at(flutter::EncodableValue("x")));
      double y = std::get<double>(args->at(flutter::EncodableValue("y")));
      MoveMouse(x, y);
      result->Success();
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments");
    }
  } else if (method_call.method_name().compare("clickMouse") == 0) {
    if (args && args->find(flutter::EncodableValue("x")) != args->end() &&
        args->find(flutter::EncodableValue("y")) != args->end() &&
        args->find(flutter::EncodableValue("button")) != args->end()) {
      double x = std::get<double>(args->at(flutter::EncodableValue("x")));
      double y = std::get<double>(args->at(flutter::EncodableValue("y")));
      std::string button = std::get<std::string>(args->at(flutter::EncodableValue("button")));
      ClickMouse(x, y, button);
      result->Success();
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments");
    }
  } else if (method_call.method_name().compare("scrollMouse") == 0) {
    if (args && args->find(flutter::EncodableValue("x")) != args->end() &&
        args->find(flutter::EncodableValue("y")) != args->end() &&
        args->find(flutter::EncodableValue("delta")) != args->end()) {
      double x = std::get<double>(args->at(flutter::EncodableValue("x")));
      double y = std::get<double>(args->at(flutter::EncodableValue("y")));
      int delta = std::get<int>(args->at(flutter::EncodableValue("delta")));
      ScrollMouse(x, y, delta);
      result->Success();
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments");
    }
  } else if (method_call.method_name().compare("pressKey") == 0) {
    if (args && args->find(flutter::EncodableValue("key")) != args->end()) {
      std::string key = std::get<std::string>(args->at(flutter::EncodableValue("key")));
      std::vector<std::string> modifiers;
      if (args->find(flutter::EncodableValue("modifiers")) != args->end()) {
        auto modifiersList = std::get<flutter::EncodableList>(args->at(flutter::EncodableValue("modifiers")));
        for (const auto& mod : modifiersList) {
          modifiers.push_back(std::get<std::string>(mod));
        }
      }
      PressKey(key, modifiers);
      result->Success();
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments");
    }
  } else if (method_call.method_name().compare("typeText") == 0) {
    if (args && args->find(flutter::EncodableValue("text")) != args->end()) {
      std::string text = std::get<std::string>(args->at(flutter::EncodableValue("text")));
      TypeText(text);
      result->Success();
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments");
    }
  } else {
    result->NotImplemented();
  }
}

void InputControlPlugin::MoveMouse(double x, double y) {
  SetCursorPos((int)x, (int)y);
}

void InputControlPlugin::ClickMouse(double x, double y, const std::string& button) {
  SetCursorPos((int)x, (int)y);
  DWORD mouseEvent = 0;
  if (button == "left") {
    mouseEvent = MOUSEEVENTF_LEFTDOWN | MOUSEEVENTF_LEFTUP;
  } else if (button == "right") {
    mouseEvent = MOUSEEVENTF_RIGHTDOWN | MOUSEEVENTF_RIGHTUP;
  } else if (button == "middle") {
    mouseEvent = MOUSEEVENTF_MIDDLEDOWN | MOUSEEVENTF_MIDDLEUP;
  }
  mouse_event(mouseEvent, 0, 0, 0, 0);
}

void InputControlPlugin::ScrollMouse(double x, double y, int delta) {
  SetCursorPos((int)x, (int)y);
  mouse_event(MOUSEEVENTF_WHEEL, 0, 0, delta, 0);
}

void InputControlPlugin::PressKey(const std::string& key, const std::vector<std::string>& modifiers) {
  // 简化实现，实际需要映射键码
  // 这里只是示例
  INPUT input = {0};
  input.type = INPUT_KEYBOARD;
  input.ki.wVk = VK_RETURN; // 示例
  SendInput(1, &input, sizeof(INPUT));
  input.ki.dwFlags = KEYEVENTF_KEYUP;
  SendInput(1, &input, sizeof(INPUT));
}

void InputControlPlugin::TypeText(const std::string& text) {
  for (char c : text) {
    INPUT input = {0};
    input.type = INPUT_KEYBOARD;
    input.ki.wVk = 0;
    input.ki.wScan = c;
    input.ki.dwFlags = KEYEVENTF_UNICODE;
    SendInput(1, &input, sizeof(INPUT));
    input.ki.dwFlags = KEYEVENTF_UNICODE | KEYEVENTF_KEYUP;
    SendInput(1, &input, sizeof(INPUT));
  }
}

void RegisterInputControlPlugin(flutter::PluginRegistrarWindows *registrar) {
  InputControlPlugin::RegisterWithRegistrar(registrar);
}

