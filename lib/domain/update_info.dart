import 'package:flutter/foundation.dart';

@immutable
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.releaseNotes,
    required this.apkUrl,
    required this.releaseDate,
    required this.apkAssetName,
  });

  final String apkAssetName;
  final String apkUrl;
  final DateTime releaseDate;
  final String? releaseNotes;
  final String version;
}
