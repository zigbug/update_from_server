import 'dart:io';

import 'package:update_from_server/update_from_server_platform_interface.dart';

class UpdateInstallException implements Exception {
  UpdateInstallException(this.message);
  final String message;
  @override
  String toString() => 'UpdateInstallException: $message';
}

/// Triggers platform-specific installation of a downloaded update artifact.
class UpdateInstaller {
  /// Installs the artifact at [filePath].
  ///
  /// On Android this launches the system package installer for an APK.
  /// On Windows/Linux this opens/runs the downloaded installer or package.
  ///
  /// Returns `true` if the install intent/process was launched successfully.
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
    final ok = await UpdateFromServerPlatform.instance.installUpdate(filePath);
    return ok ?? false;
  }
}
