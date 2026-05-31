import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/settings_provider.dart';

class SwitchConfigBottomSheet extends ConsumerWidget {
  const SwitchConfigBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final configurations = ref
        .watch(settingsControllerProvider.notifier)
        .getConfigurations();
    final activeConfigId = ref
        .watch(settingsControllerProvider.notifier)
        .getActiveConfigurationId();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Switch Configuration",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...configurations.map((config) {
            final isSelected = config.id == activeConfigId;
            return ListTile(
              leading: Icon(
                Icons.tune,
                color: isSelected ? theme.colorScheme.primary : null,
              ),
              title: Text(
                config.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () async {
                Navigator.pop(context);
                if (!isSelected) {
                  await ref
                      .read(settingsControllerProvider.notifier)
                      .switchConfiguration(config.id);
                }
              },
            );
          }),
        ],
      ),
    );
  }
}
