#include "include/update_from_server/update_from_server_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/stat.h>
#include <sys/utsname.h>

#include <cstring>

#include "update_from_server_plugin_private.h"

#define UPDATE_FROM_SERVER_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), update_from_server_plugin_get_type(), \
                              UpdateFromServerPlugin))

struct _UpdateFromServerPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(UpdateFromServerPlugin, update_from_server_plugin, g_object_get_type())

FlMethodResponse* get_platform_version() {
  struct utsname uname_data = {};
  uname(&uname_data);
  g_autofree gchar *version = g_strdup_printf("Linux %s", uname_data.version);
  g_autoptr(FlValue) result = fl_value_new_string(version);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static FlMethodResponse* install_update(FlValue* args) {
  if (fl_value_get_type(args) != FL_VALUE_TYPE_MAP) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "invalid_args", "Expected map arguments", nullptr));
  }
  FlValue* path_value = fl_value_lookup_string(args, "filePath");
  if (path_value == nullptr ||
      fl_value_get_type(path_value) != FL_VALUE_TYPE_STRING) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "invalid_args", "filePath is required", nullptr));
  }
  const gchar* path = fl_value_get_string(path_value);
  if (path == nullptr || strlen(path) == 0) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "invalid_args", "filePath must be non-empty", nullptr));
  }

  // Ensure AppImage-like binaries are executable.
  chmod(path, 0755);

  g_autofree gchar* quoted = g_shell_quote(path);
  g_autofree gchar* command = g_strdup_printf("xdg-open %s", quoted);
  gboolean ok = g_spawn_command_line_async(command, nullptr);
  if (!ok) {
    // Fallback: try to execute directly.
    g_autoptr(GError) error = nullptr;
    gchar* argv[] = {g_strdup(path), nullptr};
    ok = g_spawn_async(nullptr, argv, nullptr, G_SPAWN_SEARCH_PATH, nullptr,
                       nullptr, nullptr, &error);
    g_free(argv[0]);
  }
  if (!ok) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "install_failed", "Failed to launch installer", nullptr));
  }
  g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static void update_from_server_plugin_handle_method_call(
    UpdateFromServerPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;

  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  if (strcmp(method, "getPlatformVersion") == 0) {
    response = get_platform_version();
  } else if (strcmp(method, "installUpdate") == 0) {
    response = install_update(args);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void update_from_server_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(update_from_server_plugin_parent_class)->dispose(object);
}

static void update_from_server_plugin_class_init(UpdateFromServerPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = update_from_server_plugin_dispose;
}

static void update_from_server_plugin_init(UpdateFromServerPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  UpdateFromServerPlugin* plugin = UPDATE_FROM_SERVER_PLUGIN(user_data);
  update_from_server_plugin_handle_method_call(plugin, method_call);
}

void update_from_server_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  UpdateFromServerPlugin* plugin = UPDATE_FROM_SERVER_PLUGIN(
      g_object_new(update_from_server_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "update_from_server",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
