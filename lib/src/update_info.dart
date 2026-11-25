/// Information about an available update returned by `/api/v1/check`.
class UpdateInfo {
  const UpdateInfo({
    required this.update,
    required this.app,
    required this.name,
    required this.platform,
    required this.arch,
    required this.channel,
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.size,
    required this.sha256,
    required this.releaseNotes,
    required this.mandatory,
    required this.minVersion,
    required this.publishedAt,
  });

  /// Whether the server reports that an update is available.
  final bool update;

  final String app;
  final String name;
  final String platform;
  final String arch;
  final String channel;

  /// Semantic version string of the release (e.g. `1.2.0`).
  final String version;

  /// Integer build number of the release.
  final int buildNumber;

  /// Absolute URL to download the artifact.
  final String downloadUrl;

  /// File size in bytes.
  final int size;

  /// Lowercase hex SHA-256 of the artifact.
  final String sha256;

  final String releaseNotes;
  final bool mandatory;
  final String minVersion;
  final DateTime? publishedAt;

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      update: json['update'] == true,
      app: json['app'] as String? ?? '',
      name: json['name'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      arch: json['arch'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      version: json['version'] as String? ?? '',
      buildNumber: _asInt(json['buildNumber']),
      downloadUrl: json['downloadUrl'] as String? ?? '',
      size: _asInt(json['size']),
      sha256: (json['sha256'] as String? ?? '').toLowerCase(),
      releaseNotes: json['releaseNotes'] as String? ?? '',
      mandatory: json['mandatory'] == true,
      minVersion: json['minVersion'] as String? ?? '',
      publishedAt: json['publishedAt'] is String
          ? DateTime.tryParse(json['publishedAt'] as String)
          : null,
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
