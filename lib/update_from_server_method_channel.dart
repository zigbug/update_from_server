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
  Future<bool> canInstall() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final ok = await methodChannel.invokeMethod<bool>('canInstall');
    return ok ?? true;
  }

  @override
  Future<void> openInstallSettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    await methodChannel.invokeMethod<void>('openInstallSettings');
  }

  @override
  Future<bool?> installUpdate(String filePath) async {
    try {
      return await methodChannel.invokeMethod<bool>('installUpdate', {
        'filePath': filePath,
      });
    } on PlatformException catch (e) {
      if (e.code == 'permission_required') {
        throw UpdateInstallPermissionException(e.message ?? 'Нужно разрешение на установку');
      }
      rethrow;
    }
  }
}
