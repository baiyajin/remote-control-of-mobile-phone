#include "screen_capture_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_linux.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <vector>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <png.h>
#include <cstring>

class ScreenCapturePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarLinux *registrar);

  ScreenCapturePlugin();

  virtual ~ScreenCapturePlugin();

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
  
  std::vector<uint8_t> captureScreen();
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
    Display* display = XOpenDisplay(NULL);
    if (display) {
      int screen = DefaultScreen(display);
      int width = DisplayWidth(display, screen);
      int height = DisplayHeight(display, screen);
      XCloseDisplay(display);
      
      flutter::EncodableMap response;
      response[flutter::EncodableValue("width")] = flutter::EncodableValue(width);
      response[flutter::EncodableValue("height")] = flutter::EncodableValue(height);
      result->Success(flutter::EncodableValue(response));
    } else {
      result->Error("NO_DISPLAY", "无法打开显示", nullptr);
    }
  } else if (method_call.method_name().compare("captureScreen") == 0) {
    std::vector<uint8_t> imageData = captureScreen();
    if (!imageData.empty()) {
      result->Success(flutter::EncodableValue(imageData));
    } else {
      result->Error("CAPTURE_FAILED", "屏幕捕获失败", nullptr);
    }
  } else {
    result->NotImplemented();
  }
}

std::vector<uint8_t> ScreenCapturePlugin::captureScreen() {
  Display* display = XOpenDisplay(NULL);
  if (!display) {
    return std::vector<uint8_t>();
  }
  
  int screen = DefaultScreen(display);
  Window root = RootWindow(display, screen);
  int width = DisplayWidth(display, screen);
  int height = DisplayHeight(display, screen);
  
  XImage* image = XGetImage(display, root, 0, 0, width, height, AllPlanes, ZPixmap);
  if (!image) {
    XCloseDisplay(display);
    return std::vector<uint8_t>();
  }
  
  // 转换为 PNG
  std::vector<uint8_t> pngData;
  png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  if (!png) {
    XDestroyImage(image);
    XCloseDisplay(display);
    return std::vector<uint8_t>();
  }
  
  png_infop info = png_create_info_struct(png);
  if (!info) {
    png_destroy_write_struct(&png, NULL);
    XDestroyImage(image);
    XCloseDisplay(display);
    return std::vector<uint8_t>();
  }
  
  // 使用内存写入 PNG
  struct PngWriteData {
    std::vector<uint8_t>* data;
  };
  PngWriteData writeData;
  writeData.data = &pngData;
  
  png_set_write_fn(png, &writeData, [](png_structp png, png_bytep data, png_size_t length) {
    PngWriteData* wd = static_cast<PngWriteData*>(png_get_io_ptr(png));
    wd->data->insert(wd->data->end(), data, data + length);
  }, NULL);
  
  png_set_IHDR(png, info, width, height, 8, PNG_COLOR_TYPE_RGB, PNG_INTERLACE_NONE,
                PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
  
  png_write_info(png, info);
  
  // 转换 XImage 数据为 RGB
  std::vector<png_bytep> rowPointers(height);
  std::vector<std::vector<uint8_t>> rowData(height);
  
  for (int y = 0; y < height; y++) {
    rowData[y].resize(width * 3);
    for (int x = 0; x < width; x++) {
      unsigned long pixel = XGetPixel(image, x, y);
      rowData[y][x * 3] = (pixel >> 16) & 0xFF;     // R
      rowData[y][x * 3 + 1] = (pixel >> 8) & 0xFF;  // G
      rowData[y][x * 3 + 2] = pixel & 0xFF;         // B
    }
    rowPointers[y] = rowData[y].data();
  }
  
  png_write_image(png, rowPointers.data());
  png_write_end(png, NULL);
  png_destroy_write_struct(&png, &info);
  
  XDestroyImage(image);
  XCloseDisplay(display);
  
  return pngData;
}

void RegisterScreenCapturePlugin(flutter::PluginRegistrarLinux *registrar) {
  ScreenCapturePlugin::RegisterWithRegistrar(registrar);
}

