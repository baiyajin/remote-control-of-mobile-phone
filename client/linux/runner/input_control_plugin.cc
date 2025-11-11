#include "input_control_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_linux.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <X11/Xlib.h>
#include <X11/extensions/XTest.h>
#include <string>
#include <map>
#include <algorithm>

class InputControlPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarLinux *registrar);

  InputControlPlugin();

  virtual ~InputControlPlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  KeyCode getKeyCode(Display* display, const std::string& key);
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
  Display* display = XOpenDisplay(NULL);
  if (!display) {
    result->Error("NO_DISPLAY", "无法打开显示", nullptr);
    return;
  }
  
  const auto* args = std::get_if<flutter::EncodableMap>(method_call.arguments());
  
  if (method_call.method_name().compare("moveMouse") == 0) {
    if (args && args->find(flutter::EncodableValue("x")) != args->end() &&
        args->find(flutter::EncodableValue("y")) != args->end()) {
      double x = std::get<double>(args->at(flutter::EncodableValue("x")));
      double y = std::get<double>(args->at(flutter::EncodableValue("y")));
      XTestFakeMotionEvent(display, -1, static_cast<int>(x), static_cast<int>(y), CurrentTime);
      XFlush(display);
      result->Success();
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments", nullptr);
    }
  } else if (method_call.method_name().compare("clickMouse") == 0) {
    if (args && args->find(flutter::EncodableValue("x")) != args->end() &&
        args->find(flutter::EncodableValue("y")) != args->end() &&
        args->find(flutter::EncodableValue("button")) != args->end()) {
      double x = std::get<double>(args->at(flutter::EncodableValue("x")));
      double y = std::get<double>(args->at(flutter::EncodableValue("y")));
      std::string button = std::get<std::string>(args->at(flutter::EncodableValue("button")));
      
      unsigned int buttonCode = (button == "right") ? Button3 : Button1;
      XTestFakeMotionEvent(display, -1, static_cast<int>(x), static_cast<int>(y), CurrentTime);
      XTestFakeButtonEvent(display, buttonCode, True, CurrentTime);
      XTestFakeButtonEvent(display, buttonCode, False, CurrentTime);
      XFlush(display);
      result->Success();
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments", nullptr);
    }
  } else if (method_call.method_name().compare("pressKey") == 0) {
    if (args && args->find(flutter::EncodableValue("key")) != args->end()) {
      std::string key = std::get<std::string>(args->at(flutter::EncodableValue("key")));
      KeyCode keyCode = getKeyCode(display, key);
      if (keyCode != 0) {
        XTestFakeKeyEvent(display, keyCode, True, CurrentTime);
        XTestFakeKeyEvent(display, keyCode, False, CurrentTime);
        XFlush(display);
        result->Success();
      } else {
        result->Error("INVALID_KEY", "Invalid key", nullptr);
      }
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments", nullptr);
    }
  } else if (method_call.method_name().compare("typeText") == 0) {
    if (args && args->find(flutter::EncodableValue("text")) != args->end()) {
      std::string text = std::get<std::string>(args->at(flutter::EncodableValue("text")));
      for (char c : text) {
        KeyCode keyCode = XKeysymToKeycode(display, static_cast<KeySym>(c));
        if (keyCode != 0) {
          XTestFakeKeyEvent(display, keyCode, True, CurrentTime);
          XTestFakeKeyEvent(display, keyCode, False, CurrentTime);
        }
      }
      XFlush(display);
      result->Success();
    } else {
      result->Error("INVALID_ARGS", "Invalid arguments", nullptr);
    }
  } else {
    result->NotImplemented();
  }
  
  XCloseDisplay(display);
}

KeyCode InputControlPlugin::getKeyCode(Display* display, const std::string& key) {
  static std::map<std::string, KeySym> keyMap = {
    {"enter", XK_Return},
    {"return", XK_Return},
    {"space", XK_space},
    {"tab", XK_Tab},
    {"escape", XK_Escape},
    {"backspace", XK_BackSpace},
  };
  
  std::string lowerKey = key;
  std::transform(lowerKey.begin(), lowerKey.end(), lowerKey.begin(), ::tolower);
  
  KeySym keysym = 0;
  if (keyMap.find(lowerKey) != keyMap.end()) {
    keysym = keyMap[lowerKey];
  } else if (key.length() == 1) {
    keysym = static_cast<KeySym>(key[0]);
  }
  
  if (keysym != 0) {
    return XKeysymToKeycode(display, keysym);
  }
  return 0;
}

void RegisterInputControlPlugin(flutter::PluginRegistrarLinux *registrar) {
  InputControlPlugin::RegisterWithRegistrar(registrar);
}

