import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/logger.dart';
import '../domain/models.dart';

part 'model_manager_provider.g.dart';

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
    state = const AsyncLoading();
    WakelockPlus.enable();
    try {
      final fileType = model.fileName.endsWith('.litertlm')
          ? ModelFileType.litertlm
          : ModelFileType.task;

      await FlutterGemma.installModel(
            modelType: model.modelType,
            fileType: fileType,
          )
          .fromNetwork(model.url, token: token.isNotEmpty ? token : null)
          .withProgress((progress) {
            state = AsyncData(progress);
          })
          .install();

      state = const AsyncData(null);
      ref.invalidate(isModelInstalledProvider(model.id));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    } finally {
      WakelockPlus.disable();
    }
  }

  Future<void> deleteModel(AvailableModel model) async {
    state = const AsyncLoading();
    try {
      await FlutterGemma.uninstallModel(model.fileName);
      ref.invalidate(isModelInstalledProvider(model.id));
      state = const AsyncData(null);
      appLogger.i("✅ Model ${model.name} uninstalled successfully.");
    } catch (e, st) {
      appLogger.e("Failed to uninstall model", error: e);
      state = AsyncError(e, st);
      rethrow;
    }
  }

  @override
  AsyncValue<int?> build() {
    return const AsyncData(null);
  }
}
