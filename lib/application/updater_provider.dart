import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:local_assistant/domain/update_info.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../infrastructure/updater_service.dart';

part 'updater_provider.g.dart';

@immutable
sealed class UpdateState {
  const UpdateState();
}

class UpdateInitial extends UpdateState {
  const UpdateInitial();
}

class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

class UpdateAvailable extends UpdateState {
  const UpdateAvailable(this.info);

  final UpdateInfo info;
}

class UpdateNotAvailable extends UpdateState {
  const UpdateNotAvailable();
}

class UpdateDownloading extends UpdateState {
  const UpdateDownloading(this.progress);

  final double progress;
}

class UpdateError extends UpdateState {
  const UpdateError(this.message);

  final String message;
}

@riverpod
UpdaterService updaterService(Ref ref) {
  return UpdaterService();
}

@riverpod
class UpdaterController extends _$UpdaterController {
  Future<void> checkForUpdate() async {
    state = const UpdateChecking();
    final service = ref.read(updaterServiceProvider);
    try {
      final updateInfo = await service.checkForUpdate();
      if (!ref.mounted) return;
      if (updateInfo != null) {
        state = UpdateAvailable(updateInfo);
      } else {
        state = const UpdateNotAvailable();
      }
    } catch (e) {
      if (ref.mounted) state = UpdateError(e.toString());
    }
  }

  Future<void> downloadUpdate() async {
    final currentState = state;
    if (currentState is! UpdateAvailable) return;

    if (Platform.isAndroid) {
      state = const UpdateDownloading(0);
      final service = ref.read(updaterServiceProvider);
      try {
        await service.downloadAndInstallUpdate(currentState.info, (
          received,
          total,
        ) {
          if (total != -1 && ref.mounted && state is UpdateDownloading) {
            state = UpdateDownloading(received / total);
          }
        });
        state = currentState;
      } catch (e) {
        if (ref.mounted) state = UpdateError(e.toString());
      }
    } else {
      final url = Uri.parse(
        'https://github.com/FlamingWater35/Local-Assistant/releases/latest',
      );
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  UpdateState build() {
    if (!kIsWeb && Platform.isAndroid) {
      Future.microtask(
        () => ref.read(updaterServiceProvider).cleanupOldUpdates(),
      );

      Future.delayed(const Duration(seconds: 3), () {
        if (ref.mounted && state is UpdateInitial) {
          checkForUpdate();
        }
      });
    }
    return const UpdateInitial();
  }
}
