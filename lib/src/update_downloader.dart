import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'update_info.dart';

typedef DownloadProgress = void Function(int received, int total);

class UpdateDownloadException implements Exception {
  UpdateDownloadException(this.message);
  final String message;
  @override
  String toString() => 'UpdateDownloadException: $message';
}

/// Downloads an update artifact and verifies its SHA-256.
class UpdateDownloader {
  UpdateDownloader({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// Downloads [info.downloadUrl] to a temporary directory, reports [onProgress],
  /// verifies SHA-256 against [info.sha256], and returns the local file path.
  Future<String> download(
    UpdateInfo info, {
    DownloadProgress? onProgress,
  }) async {
    final uri = Uri.parse(info.downloadUrl);
    final request = http.Request('GET', uri);
    final response = await _http.send(request);
    if (response.statusCode != 200) {
      throw UpdateDownloadException(
        'Download failed (${response.statusCode})',
      );
    }

    final dir = await getTemporaryDirectory();
    final updatesDir = Directory(p.join(dir.path, 'update_from_server'));
    if (!await updatesDir.exists()) {
      await updatesDir.create(recursive: true);
    }
    final fileName = _fileNameFromUrl(info.downloadUrl, info.platform);
    final file = File(p.join(updatesDir.path, fileName));
    final sink = file.openWrite();

    final total = response.contentLength ?? info.size;
    var received = 0;
    final digestSink = AccumulatorSink<Digest>();
    final hasher = sha256.startChunkedConversion(digestSink);

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        hasher.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
    } finally {
      await sink.close();
    }
    hasher.close();
    final digest = digestSink.events.single.toString().toLowerCase();
    final expected = info.sha256.toLowerCase();
    if (expected.isNotEmpty && digest != expected) {
      try {
        await file.delete();
      } catch (_) {}
      throw UpdateDownloadException(
        'SHA-256 mismatch: expected $expected, got $digest',
      );
    }
    return file.path;
  }

  String _fileNameFromUrl(String url, String platform) {
    try {
      final segments = Uri.parse(url).pathSegments;
      if (segments.isNotEmpty) {
        final last = segments.last;
        if (last.isNotEmpty) return last;
      }
    } catch (_) {}
    return switch (platform) {
      'windows' => 'update.exe',
      'linux' => 'update.bin',
      _ => 'update.apk',
    };
  }
}

/// Minimal sink to capture the final [Digest] from chunked conversion.
class AccumulatorSink<T> implements Sink<T> {
  final List<T> events = <T>[];
  @override
  void add(T data) => events.add(data);
  @override
  void close() {}
}
