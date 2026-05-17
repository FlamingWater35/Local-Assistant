import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_assistant/application/device_info_provider.dart';
import 'package:local_assistant/core/constants.dart';
import 'package:local_assistant/i18n/generated/translations.g.dart';

class RamIndicator extends ConsumerWidget {
  const RamIndicator({super.key, required this.maxTokens});

  final int maxTokens;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final ramAsync = ref.watch(deviceRamGbProvider);
    final ramGb = ramAsync.value ?? 0.0;
    final isSafe = AppConstants.isMemorySafe(ramGb, maxTokens);
    final safeColor = theme.brightness == Brightness.dark
        ? Colors.green.shade400
        : Colors.green.shade700;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSafe
            ? Colors.green.withValues(alpha: 0.1)
            : theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSafe ? safeColor : theme.colorScheme.error,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.memory,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                ramGb > 0
                    ? t.settings.ramIndicator.detected(
                        ram: ramGb.toStringAsFixed(1),
                      )
                    : t.settings.ramIndicator.unknown,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isSafe
                ? t.settings.ramIndicator.safe
                : t.settings.ramIndicator.warning,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSafe ? safeColor : theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
