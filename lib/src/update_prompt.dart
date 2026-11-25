import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'ota_client.dart';
import 'update_downloader.dart';
import 'update_info.dart';
import 'update_installer.dart';

/// Checks for an update and, if available, shows a prompt to the user.
///
/// When the user confirms, the update is downloaded (with SHA-256 verification)
/// and the platform installer is launched.
///
/// Returns `true` if an install flow was started.
Future<bool> checkAndPromptUpdate(
  BuildContext context, {
  required OtaClient client,
  String channel = 'stable',
  String arch = 'universal',
  String? platform,
  String? currentVersion,
  int? currentBuildNumber,
  bool usePackageInfo = true,
}) async {
  final resolvedPlatform = platform ?? _defaultPlatform();
  var version = currentVersion;
  var build = currentBuildNumber;
  if (usePackageInfo && (version == null || build == null)) {
    try {
      final info = await PackageInfo.fromPlatform();
      version ??= info.version;
      build ??= int.tryParse(info.buildNumber);
    } catch (_) {}
  }

  final update = await client.check(
    platform: resolvedPlatform,
    channel: channel,
    arch: arch,
    currentVersion: version,
    currentBuildNumber: build,
  );
  if (update == null || !context.mounted) return false;

  final accepted = await _showUpdateDialog(context, update);
  if (accepted != true || !context.mounted) return false;

  await _downloadAndInstall(context, update);
  return true;
}

String _defaultPlatform() {
  if (Platform.isAndroid) return 'android';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  return 'android';
}

Future<bool?> _showUpdateDialog(BuildContext context, UpdateInfo update) {
  final notes = update.releaseNotes.trim();
  return showDialog<bool>(
    context: context,
    barrierDismissible: !update.mandatory,
    builder: (ctx) => PopScope(
      canPop: !update.mandatory,
      child: AlertDialog(
        title: Text(update.mandatory ? 'Требуется обновление' : 'Доступно обновление'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${update.name.isNotEmpty ? update.name : update.app} ${update.version} (${update.buildNumber})'),
              if (update.size > 0) ...[
                const SizedBox(height: 4),
                Text('Размер: ${_formatBytes(update.size)}',
                    style: Theme.of(ctx).textTheme.bodySmall),
              ],
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Что нового:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(notes),
              ],
            ],
          ),
        ),
        actions: [
          if (!update.mandatory)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Позже'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Установить'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _downloadAndInstall(BuildContext context, UpdateInfo update) async {
  final progress = ValueNotifier<double?>(null);
  final status = ValueNotifier<String>('Подготовка...');

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('Загрузка обновления'),
        content: ValueListenableBuilder<double?>(
          valueListenable: progress,
          builder: (ctx, value, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: value),
              const SizedBox(height: 12),
              ValueListenableBuilder<String>(
                valueListenable: status,
                builder: (ctx, text, _) => Text(text),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    final downloader = UpdateDownloader();
    final path = await downloader.download(
      update,
      onProgress: (received, total) {
        if (total > 0) {
          progress.value = received / total;
          status.value = '${_formatBytes(received)} / ${_formatBytes(total)}';
        } else {
          progress.value = null;
          status.value = _formatBytes(received);
        }
      },
    );
    status.value = 'Запуск установки...';
    progress.value = null;
    await UpdateInstaller.install(path);
  } on UpdateInstallPermissionException catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Нужно разрешение'),
          content: Text(
            '${e.message}\n\nОткройте настройки и разрешите установку приложений из этого источника, затем вернитесь и нажмите «Установить» снова.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () async {
                await UpdateInstaller.openInstallSettings();
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Открыть настройки'),
            ),
          ],
        ),
      );
      return;
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Ошибка обновления'),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
  }
  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}

String _formatBytes(int bytes) {
  const units = ['Б', 'КБ', 'МБ', 'ГБ'];
  double value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text = value >= 10 || unit == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}
