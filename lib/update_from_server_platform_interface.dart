import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'update_from_server_method_channel.dart';

abstract class UpdateFromServerPlatform extends PlatformInterface {
  UpdateFromServerPlatform() : super(token: _token);

  static final Object _token = Object();

  static UpdateFromServerPlatform _instance = MethodChannelUpdateFromServer();

  static UpdateFromServerPlatform get instance => _instance;

  static set instance(UpdateFromServerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  /// Launches platform-specific installation for the artifact at [filePath].
  /// Returns true if the install flow was started.
  Future<bool?> installUpdate(String filePath) {
    throw UnimplementedError('installUpdate() has not been implemented.');
  }
}
