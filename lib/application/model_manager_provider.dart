import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/logger.dart';
import '../domain/models.dart';
import '../infrastructure/hive_service.dart';

part 'model_manager_provider.g.dart';

class DownloadStatus {
  const DownloadStatus({
    this.progress = 0,
    this.isDownloading = false,
    this.isPaused = false,
    this.error,
    this.estimatedTimeRemaining = 0,
  });

  final String? error;
  final double estimatedTimeRemaining;
  final bool isDownloading;
  final bool isPaused;
  final int progress;
}

@riverpod
Future<bool> isModelInstalled(Ref ref, String modelId) async {
  final modelDef = kAvailableModels.firstWhere(
    (m) => m.id == modelId,
    orElse: () => kAvailableModels.first,
  );
  return await FlutterGemma.isModelInstalled(modelDef.fileName);
}

@Riverpod(keepAlive: true)
class ModelDownloader extends _$ModelDownloader {
  Future<void> download(AvailableModel model, String token) async {
    final hive = ref.read(hiveServiceProvider);
    await hive.setInterruptedDownload(model.id, 0);

    state = {
      ...state,
      model.id: const DownloadStatus(isDownloading: true, progress: 0),
    };
    WakelockPlus.enable();

    int lastProgress = 0;
    DateTime lastTime = DateTime.now();

    try {
      final fileType = model.fileName.endsWith('.litertlm')
          ? ModelFileType.litertlm
          : ModelFileType.task;

      final bool useForeground = model.sizeMb >= 1000;

      await FlutterGemma.installModel(
            modelType: model.modelType,
            fileType: fileType,
          )
          .fromNetwork(
            model.url,
            token: token.isNotEmpty ? token : null,
            foreground: useForeground,
          )
          .withProgress((progress) {
            final now = DateTime.now();
            final timeDiff = now.difference(lastTime).inMilliseconds;
            double estimatedTime = state[model.id]?.estimatedTimeRemaining ?? 0;

            if (timeDiff > 1000 && progress > lastProgress) {
              final progressDiff = progress - lastProgress;
              final speed = progressDiff / (timeDiff / 1000);
              final remainingProgress = 100 - progress;
              estimatedTime = remainingProgress / speed;
              lastProgress = progress;
              lastTime = now;
              hive.setInterruptedDownload(model.id, progress);
            } else if (lastProgress == 0) {
              lastProgress = progress;
              lastTime = now;
            }

            state = {
              ...state,
              model.id: DownloadStatus(
                isDownloading: true,
                progress: progress,
                estimatedTimeRemaining: estimatedTime,
              ),
            };
          })
          .install();

      await hive.setInterruptedDownload(null);
      state = {
        ...state,
        model.id: const DownloadStatus(isDownloading: false, progress: 100),
      };
      ref.invalidate(isModelInstalledProvider(model.id));
    } catch (e) {
      hive.setInterruptedDownload(model.id, lastProgress);
      state = {
        ...state,
        model.id: DownloadStatus(
          isDownloading: false,
          error: e.toString(),
          isPaused: true,
          progress: lastProgress,
        ),
      };
      rethrow;
    } finally {
      WakelockPlus.disable();
    }
  }

  Future<void> deleteModel(AvailableModel model) async {
    final hive = ref.read(hiveServiceProvider);
    if (hive.getInterruptedDownload() == model.id) {
      await hive.setInterruptedDownload(null);
      state = {...state, model.id: const DownloadStatus()};
    }

    try {
      await FlutterGemma.uninstallModel(model.fileName);
      ref.invalidate(isModelInstalledProvider(model.id));
      appLogger.i("✅ Model ${model.name} uninstalled successfully.");
    } catch (e) {
      appLogger.e("Failed to uninstall model", error: e);
      rethrow;
    }
  }

  @override
  Map<String, DownloadStatus> build() {
    final hive = ref.watch(hiveServiceProvider);
    final interrupted = hive.getInterruptedDownload();
    final interruptedProgress = hive.getInterruptedDownloadProgress();
    if (interrupted != null) {
      return {
        interrupted: DownloadStatus(
          isPaused: true,
          progress: interruptedProgress,
        ),
      };
    }
    return {};
  }
}
