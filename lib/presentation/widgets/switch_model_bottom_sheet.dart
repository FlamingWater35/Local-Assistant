import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/model_manager_provider.dart';
import '../../application/settings_provider.dart';
import '../../domain/models.dart';
import '../../i18n/generated/translations.g.dart';
import '../../router/app_router.dart';

class SwitchModelBottomSheet extends ConsumerWidget {
  const SwitchModelBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final currentSettings = ref.watch(settingsControllerProvider);

    final downloadedModels = kAvailableModels.where((m) {
      return ref.watch(isModelInstalledProvider(m.id)).value == true;
    }).toList();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              t.chat.switchModel,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (downloadedModels.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ...downloadedModels.map((model) {
            final isSelected = model.id == currentSettings.selectedModel;
            return ListTile(
              leading: Icon(
                Icons.smart_toy,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
              title: Text(
                model.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                Navigator.pop(context);
                if (!isSelected) {
                  ref
                      .read(settingsControllerProvider.notifier)
                      .updateSettings(
                        currentSettings.copyWith(selectedModel: model.id),
                        reloadModel: true,
                      );
                }
              },
            );
          }),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(t.chat.manageModels),
            onTap: () {
              Navigator.pop(context);
              context.router.push(const ModelMenuRoute());
            },
          ),
        ],
      ),
    );
  }
}
