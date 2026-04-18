import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:local_assistant/domain/update_info.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pub_semver/pub_semver.dart';

import '../core/logger.dart';

const _githubOwner = 'FlamingWater35';
const _githubRepo = 'Local-Assistant';
const _githubApiUrl =
    'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';

class UpdaterService {
  final Dio _dio = Dio();

  Future<void> cleanupOldUpdates() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final directory = Directory(tempDir.path);

      if (await directory.exists()) {
        final List<FileSystemEntity> files = directory.listSync();
        for (var file in files) {
          if (file is File && file.path.endsWith('.apk')) {
            appLogger.i('Cleaning up old update file: ${file.path}');
            await file.delete();
          }
        }
      }
    } catch (e) {
      appLogger.w('Failed to cleanup old updates: $e');
    }
  }

  Future<UpdateInfo?> checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return null;

    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(info.version);
      appLogger.i('Current app version: $currentVersion');

      final response = await http.get(Uri.parse(_githubApiUrl));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final latestVersionStr = (json['tag_name'] as String).replaceAll(
          'v',
          '',
        );
        final latestVersion = Version.parse(latestVersionStr);

        appLogger.i('Latest GitHub release version: $latestVersion');

        if (latestVersion > currentVersion) {
          final assets = json['assets'] as List;

          final targetAsset = assets.firstWhere(
            (a) => (a['name'] as String).contains('arm64-v8a.apk'),
            orElse: () => assets.firstWhere(
              (a) => (a['name'] as String).endsWith('.apk'),
              orElse: () => null,
            ),
          );

          if (targetAsset != null) {
            return UpdateInfo(
              version: latestVersionStr,
              releaseNotes: json['body'],
              releaseDate: DateTime.parse(json['published_at']),
              apkUrl: targetAsset['browser_download_url'],
              apkAssetName: targetAsset['name'],
            );
          }
        }
      }
    } catch (e) {
      appLogger.e('Error checking for updates', error: e);
    }
    return null;
  }

  Future<void> downloadAndInstallUpdate(
    UpdateInfo updateInfo,
    void Function(int, int) onReceiveProgress,
  ) async {
    if (!Platform.isAndroid) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${updateInfo.apkAssetName}';

      appLogger.i('Downloading update: ${updateInfo.apkUrl}');

      await _dio.download(
        updateInfo.apkUrl,
        filePath,
        onReceiveProgress: onReceiveProgress,
      );

      appLogger.i('Download complete. Opening APK...');
      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        throw Exception('Could not open APK: ${result.message}');
      }
    } catch (e) {
      appLogger.e('Error during install', error: e);
      rethrow;
    }
  }
}
