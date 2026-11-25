import 'dart:convert';

import 'package:http/http.dart' as http;

import 'update_info.dart';

/// Client for the updates.905911.ru-compatible OTA server.
class OtaClient {
  OtaClient({
    required this.baseUrl,
    this.appKey,
    this.packageName,
    http.Client? httpClient,
  })  : assert(appKey != null || packageName != null,
            'Either appKey or packageName must be provided'),
        _http = httpClient ?? http.Client();

  /// Public origin of the server, e.g. `https://updates.905911.ru:8450`.
  final String baseUrl;

  /// Application key registered on the server.
  final String? appKey;

  /// Android package name (alternative to [appKey]).
  final String? packageName;

  final http.Client _http;

  /// Checks for updates using `/api/v1/check`.
  ///
  /// Returns an [UpdateInfo] with `update == true` when a newer release is
  /// available, or `null` when there is no update.
  ///
  /// [currentBuildNumber] takes priority over [currentVersion] on the server.
  Future<UpdateInfo?> check({
    String platform = 'android',
    String channel = 'stable',
    String arch = 'universal',
    String? currentVersion,
    int? currentBuildNumber,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/check').replace(queryParameters: {
      'key': ?appKey,
      if (appKey == null) 'package': ?packageName,
      'platform': platform,
      'channel': channel,
      'arch': arch,
      'version': ?currentVersion,
      if (currentBuildNumber != null) 'build': '$currentBuildNumber',
    });

    final response = await _http.get(uri);
    if (response.statusCode != 200) {
      throw OtaException(
        'Update check failed (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final info = UpdateInfo.fromJson(data);
    if (!info.update) return null;
    return info;
  }

  /// Closes the underlying HTTP client if it was created by this instance.
  void close() => _http.close();
}

class OtaException implements Exception {
  OtaException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'OtaException: $message';
}
