import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
  @override
  AsyncValue<int?> build() {
    return const AsyncData(null);
  }

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
}
