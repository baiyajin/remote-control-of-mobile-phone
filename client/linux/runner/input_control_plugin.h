#ifndef RUNNER_INPUT_CONTROL_PLUGIN_H_
#define RUNNER_INPUT_CONTROL_PLUGIN_H_

#include <flutter/plugin_registrar_linux.h>
#include <X11/Xlib.h>
#include <X11/keysym.h>
#include <string>

typedef unsigned char KeyCode;

void RegisterInputControlPlugin(flutter::PluginRegistrarLinux *registrar);

#endif  // RUNNER_INPUT_CONTROL_PLUGIN_H_

