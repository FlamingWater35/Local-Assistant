import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_assistant/domain/models.dart';
import 'package:local_assistant/i18n/generated/translations.g.dart';

class ConfigurationSelector extends ConsumerWidget {
  const ConfigurationSelector({
    super.key,
    required this.activeConfigId,
    required this.configurations,
    required this.activeConfig,
    required this.onSwitch,
    required this.onAdd,
    required this.onRename,
    required this.onDelete,
  });

  final String activeConfigId;
  final List<SettingConfiguration> configurations;
  final SettingConfiguration activeConfig;
  final void Function(String configId) onSwitch;
  final VoidCallback onAdd;
  final void Function(SettingConfiguration config) onRename;
  final void Function(SettingConfiguration config) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.tune, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    t.settings.configurations.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    color: theme.colorScheme.primary,
                    tooltip: t.settings.configurations.add,
                    onPressed: onAdd,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: activeConfigId,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    icon: Icon(
                      Icons.unfold_more,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    items: configurations.map((config) {
                      final isActive = config.id == activeConfigId;
                      return DropdownMenuItem<String>(
                        value: config.id,
                        child: Row(
                          children: [
                            Icon(
                              isActive
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              size: 18,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                config.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      if (value != null && value != activeConfigId) {
                        onSwitch(value);
                      }
                    },
                  ),
                ),
              ),
              if (configurations.length > 1 || activeConfigId != 'default')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(t.settings.configurations.rename),
                        onPressed: () => onRename(activeConfig),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      if (configurations.length > 1)
                        TextButton.icon(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                          label: Text(
                            t.common.delete,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                          onPressed: () => onDelete(activeConfig),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
