import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/logger.dart';
import '../domain/models.dart';
import '../infrastructure/hive_service.dart';

part 'model_manager_provider.g.dart';

// Represents the snapshot of an active model download operation
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

// Queries whether a specific model's file is present on local storage
@riverpod
Future<bool> isModelInstalled(Ref ref, String modelId) async {
  try {
    final modelDef = kAvailableModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => kAvailableModels.first,
    );
    return await FlutterGemma.isModelInstalled(modelDef.fileName);
  } catch (e, st) {
    appLogger.e(
      "Failed to check if model $modelId is installed",
      error: e,
      stackTrace: st,
    );
    return false;
  }
}

// Manages downloading, pausing, and deleting LLM model assets locally
@Riverpod(keepAlive: true)
class ModelDownloader extends _$ModelDownloader {
  // Initiates downloading a selected model while reporting progress to the UI
  Future<void> download(AvailableModel model, String token) async {
    final hive = ref.read(hiveServiceProvider);

    try {
      await hive.setInterruptedDownload(model.id, 0);
    } catch (e) {
      appLogger.w(
        "Failed to save initial download interruption state",
        error: e,
      );
    }

    state = {
      ...state,
      model.id: const DownloadStatus(isDownloading: true, progress: 0),
    };

    try {
      WakelockPlus.enable();
    } catch (e) {
      appLogger.w("Could not acquire Wakelock during model download", error: e);
    }

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

              try {
                hive.setInterruptedDownload(model.id, progress);
              } catch (e) {
                appLogger.d(
                  "Failed to update interruption checkpoint",
                  error: e,
                );
              }
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

      try {
        await hive.setInterruptedDownload(null);
      } catch (e) {
        appLogger.w(
          "Failed to clear interruption state on successful download",
          error: e,
        );
      }

      state = {
        ...state,
        model.id: const DownloadStatus(isDownloading: false, progress: 100),
      };
      ref.invalidate(isModelInstalledProvider(model.id));
    } catch (e, st) {
      appLogger.e(
        "Model download failed for ID: ${model.id}",
        error: e,
        stackTrace: st,
      );

      try {
        hive.setInterruptedDownload(model.id, lastProgress);
      } catch (dbError) {
        appLogger.e(
          "Failed to register paused download state in DB",
          error: dbError,
        );
      }

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
      try {
        WakelockPlus.disable();
      } catch (e) {
        appLogger.d("Wakelock already disabled", error: e);
      }
    }
  }

  // Deletes an installed model from local disk storage
  Future<void> deleteModel(AvailableModel model) async {
    final hive = ref.read(hiveServiceProvider);

    try {
      if (hive.getInterruptedDownload() == model.id) {
        await hive.setInterruptedDownload(null);
        state = {...state, model.id: const DownloadStatus()};
      }
    } catch (e) {
      appLogger.w(
        "Error clearing interrupted download flag during deletion",
        error: e,
      );
    }

    try {
      await FlutterGemma.uninstallModel(model.fileName);
      ref.invalidate(isModelInstalledProvider(model.id));
      appLogger.i("✅ Model ${model.name} uninstalled successfully.");
    } catch (e, st) {
      appLogger.e(
        "Failed to uninstall model ${model.name}",
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Map<String, DownloadStatus> build() {
    try {
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
    } catch (e, st) {
      appLogger.e(
        "Error building model downloader state",
        error: e,
        stackTrace: st,
      );
    }
    return {};
  }
}
