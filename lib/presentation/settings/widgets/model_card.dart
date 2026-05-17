import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_assistant/application/model_manager_provider.dart';
import 'package:local_assistant/domain/models.dart';
import 'package:local_assistant/i18n/generated/translations.g.dart';

class ModelCard extends ConsumerWidget {
  const ModelCard({
    super.key,
    required this.selectedModelDef,
    required this.onTap,
  });

  final AvailableModel selectedModelDef;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final isInstalled = ref.watch(
      isModelInstalledProvider(selectedModelDef.id),
    );

    return Card.filled(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isInstalled.value == true
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : theme.colorScheme.errorContainer.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.smart_toy,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedModelDef.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    isInstalled.when(
                      data: (installed) => Text(
                        installed
                            ? t.settings.readyToUse
                            : t.settings.notDownloaded,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: installed
                              ? Colors.green.shade600
                              : theme.colorScheme.error,
                        ),
                      ),
                      loading: () => Text(
                        t.settings.checkingStatus,
                        style: theme.textTheme.bodySmall,
                      ),
                      error: (_, _) => Text(
                        t.settings.errorCheckingStatus,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
