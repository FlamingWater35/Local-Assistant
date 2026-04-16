import 'dart:io';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

@riverpod
class ModelDownloader extends _$ModelDownloader {
  Future<void> download(AvailableModel model, String token) async {
    state = const AsyncLoading();
    try {
      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
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
    }
  }

  Future<void> deleteModel(AvailableModel model) async {
    state = const AsyncLoading();
    try {
      final dirs = <Directory>[];
      try {
        dirs.add(await getApplicationDocumentsDirectory());
      } catch (_) {}
      try {
        dirs.add(await getApplicationSupportDirectory());
      } catch (_) {}
      if (Platform.isIOS || Platform.isMacOS) {
        try {
          dirs.add(await getLibraryDirectory());
        } catch (_) {}
      }

      bool deleted = false;
      for (final dir in dirs) {
        final file = File('${dir.path}/${model.fileName}');
        if (await file.exists()) {
          await file.delete();
          deleted = true;
        }
      }

      if (!deleted) {
        appLogger.w("Could not find file ${model.fileName} to delete.");
      }

      ref.invalidate(isModelInstalledProvider(model.id));
      state = const AsyncData(null);
    } catch (e, st) {
      appLogger.e("Failed to delete model", error: e);
      state = AsyncError(e, st);
    }
  }

  @override
  AsyncValue<int?> build() {
    return const AsyncData(null);
  }
}
