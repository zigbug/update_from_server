import 'dart:io';

import 'package:update_from_server/update_from_server_platform_interface.dart';

class UpdateInstallException implements Exception {
  UpdateInstallException(this.message);
  final String message;
  @override
  String toString() => 'UpdateInstallException: $message';
}

class UpdateInstallPermissionException extends UpdateInstallException {
  UpdateInstallPermissionException([super.message = 'Нужно разрешение на установку из неизвестных источников']);
}

/// Triggers platform-specific installation of a downloaded update artifact.
class UpdateInstaller {
  /// Installs the artifact at [filePath].
  ///
  /// On Android this launches the system package installer for an APK.
  /// On Windows/Linux this opens/runs the downloaded installer or package.
  ///
  /// Returns `true` if the install intent/process was launched successfully.
  static Future<void> openInstallSettings() async {
    await UpdateFromServerPlatform.instance.openInstallSettings();
  }

  static Future<bool> install(String filePath) async {
    if (!Platform.isAndroid && !Platform.isWindows && !Platform.isLinux) {
      throw UpdateInstallException(
        'Unsupported platform for installation',
      );
    }
    final file = File(filePath);
    if (!await file.exists()) {
      throw UpdateInstallException('Installer file not found: $filePath');
    }
    if (Platform.isAndroid) {
      final can = await UpdateFromServerPlatform.instance.canInstall();
      if (!can) {
        throw UpdateInstallPermissionException();
      }
    }
    final ok = await UpdateFromServerPlatform.instance.installUpdate(filePath);
    return ok ?? false;
  }
}
