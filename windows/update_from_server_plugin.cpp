#include "update_from_server_plugin.h"

#include <windows.h>
#include <shellapi.h>
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>
#include <string>

namespace update_from_server {

namespace {

std::wstring Utf16FromUtf8(const std::string& utf8) {
  if (utf8.empty()) return std::wstring();
  int size = MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, nullptr, 0);
  if (size <= 0) return std::wstring();
  std::wstring wide(size - 1, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, utf8.c_str(), -1, &wide[0], size);
  return wide;
}

}  // namespace

void UpdateFromServerPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "update_from_server",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<UpdateFromServerPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

UpdateFromServerPlugin::UpdateFromServerPlugin() {}

UpdateFromServerPlugin::~UpdateFromServerPlugin() {}

void UpdateFromServerPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
  } else if (method_call.method_name().compare("installUpdate") == 0) {
    const auto* args =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!args) {
      result->Error("invalid_args", "Expected map arguments");
      return;
    }
    auto it = args->find(flutter::EncodableValue("filePath"));
    if (it == args->end()) {
      result->Error("invalid_args", "filePath is required");
      return;
    }
    const auto* path = std::get_if<std::string>(&it->second);
    if (!path || path->empty()) {
      result->Error("invalid_args", "filePath must be a non-empty string");
      return;
    }
    std::wstring wide_path = Utf16FromUtf8(*path);
    HINSTANCE code = ShellExecuteW(nullptr, L"open", wide_path.c_str(), nullptr,
                                   nullptr, SW_SHOWNORMAL);
    if (reinterpret_cast<intptr_t>(code) <= 32) {
      result->Error("install_failed", "Failed to launch installer");
      return;
    }
    result->Success(flutter::EncodableValue(true));
  } else {
    result->NotImplemented();
  }
}

}  // namespace update_from_server
