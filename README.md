# update_from_server

Flutter plugin/client for a self-hosted OTA update server compatible with
[`updates.905911.ru` API](https://github.com/zigbug/updates).

Checks for a new version, shows a prompt, downloads the artifact with SHA-256
verification, and launches platform installation on **Android**, **Windows**,
and **Linux**.

## Features

- Update check via `GET /api/v1/check` (`key` or `package`, `platform`, `channel`, `arch`, current `version`/`build`).
- Parses update metadata: version, build number, download URL, size, SHA-256, release notes, mandatory flag.
- Downloads with progress callback and SHA-256 verification.
- Ready-to-use UI flow: prompt dialog → progress dialog → install.
- Platform install:
  - **Android**: launches system APK installer (`FileProvider` + `ACTION_VIEW`, requests `REQUEST_INSTALL_PACKAGES`).
  - **Windows**: opens the downloaded installer (`.exe`/`.msi`, etc.) via the default handler.
  - **Linux**: makes the artifact executable and opens it via `xdg-open` (works well for AppImage; other formats depend on system handlers).

## Getting started

Add the dependency:

```yaml
dependencies:
  update_from_server: ^0.1.0
```

Server must expose the compatible API (see the linked service). Your app must be
registered on the server and releases uploaded for the target `platform`/`arch`.

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:update_from_server/update_from_server.dart';

final ota = OtaClient(
  baseUrl: 'https://updates.example.com:8450',
  appKey: 'my_app_key', // or: packageName: 'com.example.app'
);

Future<void> checkUpdates(BuildContext context) async {
  await checkAndPromptUpdate(
    context,
    client: ota,
    channel: 'stable',
    // platform/arch/version/build are auto-detected when possible; override if needed:
    // platform: 'android', // 'android' | 'windows' | 'linux'
    // arch: 'arm64-v8a',
  );
}
```

### Manual flow

```dart
final info = await ota.check(
  platform: 'windows',
  channel: 'stable',
  arch: 'x64',
  currentVersion: '1.0.0',
  currentBuildNumber: 1,
);

if (info != null) {
  final path = await UpdateDownloader().download(
    info,
    onProgress: (received, total) {
      // update UI
    },
  );
  await UpdateInstaller.install(path);
}
```

## Notes

- **Android**: if "Install unknown apps" is not allowed for your app, the system
  settings screen may be shown; the user must grant permission and retry.
- **Windows/Linux**: "install" means launching the downloaded artifact/installer;
  the exact behavior depends on the artifact type and OS configuration.
- Current version/build are read via `package_info_plus` by default in
  `checkAndPromptUpdate`. You can pass `currentVersion`/`currentBuildNumber`
  explicitly.
- Always publish releases with correct `platform`, `arch`, and SHA-256 (handled
  by the server on upload).

## Additional information

This package implements the public client side of the `updates` service API.
Report issues and contribute via the repository linked above. Verify behavior
with your own server and installer formats before publishing to production.