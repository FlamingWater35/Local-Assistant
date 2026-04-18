import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/logger.dart';

part 'device_info_provider.g.dart';

@Riverpod(keepAlive: true)
Future<double> deviceRamGb(Ref ref) async {
  if (kIsWeb) return 0.0;

  try {
    final plugin = DeviceInfoPlugin();
    int ramRaw = 0;

    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      final data = info.data;
      if (data.containsKey('physicalRamSize')) {
        final val = data['physicalRamSize'];
        if (val is num) ramRaw = val.toInt();
      }
    } else if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      final data = info.data;
      if (data.containsKey('physicalRamSize')) {
        final val = data['physicalRamSize'];
        if (val is num) ramRaw = val.toInt();
      }
    }

    if (ramRaw > 0) {
      return ramRaw / 1024;
    }
  } catch (e) {
    appLogger.e("Failed to get RAM info", error: e);
  }
  return 0.0;
}
