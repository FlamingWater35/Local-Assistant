import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/settings_provider.dart';
import '../../core/constants.dart';
import '../../domain/models.dart';
import '../../i18n/generated/translations.g.dart';
import '../../infrastructure/llm_service.dart';
import 'switch_model_bottom_sheet.dart';

class ModelStatusAppBarTitle extends ConsumerWidget {
  const ModelStatusAppBarTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(modelStatusProvider);
    final settings = ref.watch(settingsControllerProvider);
    final currentModel = kAvailableModels.firstWhere(
      (m) => m.id == settings.selectedModel,
      orElse: () => kAvailableModels.first,
    );
    final t = Translations.of(context);

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => const SwitchModelBottomSheet(),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == ModelState.loading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (status == ModelState.ready)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              )
            else
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                status == ModelState.loading
                    ? t.chat.loadingModel(name: currentModel.name)
                    : currentModel.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}
