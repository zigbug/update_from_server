#include "include/update_from_server/update_from_server_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "update_from_server_plugin.h"

void UpdateFromServerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  update_from_server::UpdateFromServerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
