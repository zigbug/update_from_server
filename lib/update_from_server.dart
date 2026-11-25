/// Flutter client for a self-hosted updates server
/// (https://github.com/zigbug/updates).
///
/// Provides update checking via `/api/v1/check`, file download with SHA-256
/// verification, and platform-specific installation on Android, Windows, and
/// Linux.
library;

export 'src/ota_client.dart';
export 'src/update_downloader.dart';
export 'src/update_info.dart';
export 'src/update_installer.dart';
export 'src/update_prompt.dart';
export 'update_from_server_platform_interface.dart';