import 'package:flutter_test/flutter_test.dart';
import 'package:update_from_server/update_from_server.dart';

void main() {
  test('UpdateInfo.fromJson parses check response', () {
    final info = UpdateInfo.fromJson({
      'update': true,
      'app': 'my_app',
      'name': 'My App',
      'platform': 'android',
      'arch': 'arm64-v8a',
      'channel': 'stable',
      'version': '1.2.0',
      'buildNumber': 12,
      'downloadUrl': 'https://example.com/files/abc/app.apk',
      'size': 24512345,
      'sha256': 'ABCDEF',
      'releaseNotes': 'Что нового',
      'mandatory': false,
      'minVersion': '',
      'publishedAt': '2026-11-13T12:00:00Z',
    });

    expect(info.update, isTrue);
    expect(info.app, 'my_app');
    expect(info.version, '1.2.0');
    expect(info.buildNumber, 12);
    expect(info.downloadUrl, 'https://example.com/files/abc/app.apk');
    expect(info.sha256, 'abcdef');
    expect(info.mandatory, isFalse);
    expect(info.publishedAt, isNotNull);
  });

  test('UpdateInfo.fromJson parses no-update response', () {
    final info = UpdateInfo.fromJson({
      'update': false,
      'app': 'my_app',
      'name': 'My App',
    });
    expect(info.update, isFalse);
    expect(info.version, '');
    expect(info.buildNumber, 0);
  });
}