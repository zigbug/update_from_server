import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'update_from_server_platform_interface.dart';

/// Method-channel implementation of [UpdateFromServerPlatform].
class MethodChannelUpdateFromServer extends UpdateFromServerPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('update_from_server');

  @override
  Future<String?> getPlatformVersion() async {
    return methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<bool?> installUpdate(String filePath) async {
    return methodChannel.invokeMethod<bool>('installUpdate', {
      'filePath': filePath,
    });
  }
}
