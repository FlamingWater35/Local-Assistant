import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_assistant/core/snackbar_helper.dart';
import 'package:local_assistant/domain/models.dart';
import 'package:local_assistant/i18n/generated/translations.g.dart';
import 'package:path_provider/path_provider.dart';

class ConfigurationSelector extends ConsumerWidget {
  const ConfigurationSelector({
    super.key,
    required this.activeConfigId,
    required this.configurations,
    required this.onSwitch,
    required this.onAdd,
    required this.onRename,
    required this.onDelete,
    required this.onDuplicate,
    required this.onToggleReadOnly,
    required this.onImport,
  });

  final String activeConfigId;
  final List<SettingConfiguration> configurations;
  final VoidCallback onAdd;
  final void Function(SettingConfiguration config) onDelete;
  final void Function(SettingConfiguration config) onDuplicate;
  final VoidCallback onImport;
  final void Function(SettingConfiguration config) onRename;
  final void Function(String configId) onSwitch;
  final void Function(SettingConfiguration config, bool isReadOnly)
  onToggleReadOnly;

  void _exportConfig(BuildContext context, SettingConfiguration config) async {
    final t = Translations.of(context);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/${config.name}.json');
    await file.writeAsString(jsonEncode(config.toJson()));

    final params = SaveFileDialogParams(
      sourceFilePath: file.path,
      fileName: "${config.name}.json",
    );
    final filePath = await FlutterFileDialog.saveFile(params: params);

    if (!context.mounted) return;
    if (filePath != null) {
      showSuccessSnackBar(context, t.settings.configurations.exportSuccess);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = Translations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.settings.configurations.yourConfigurations,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.download_outlined),
                  tooltip: t.settings.configurations.importFromFiles,
                  onPressed: onImport,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: t.settings.configurations.add,
                  onPressed: onAdd,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...configurations.map((config) {
          final isActive = config.id == activeConfigId;
          return Card(
            elevation: isActive ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: isActive ? 2 : 1,
              ),
            ),
            child: ListTile(
              leading: Icon(
                isActive
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              title: Text(
                config.name,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: config.isReadOnly
                  ? Text(
                      t.settings.configurations.readOnly,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    )
                  : null,
              onTap: () => onSwitch(config.id),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'rename') {
                    onRename(config);
                  }
                  if (value == 'duplicate') {
                    onDuplicate(config);
                  }
                  if (value == 'export') {
                    _exportConfig(context, config);
                  }
                  if (value == 'delete') {
                    onDelete(config);
                  }
                  if (value == 'toggle_readonly') {
                    onToggleReadOnly(config, !config.isReadOnly);
                  }
                },
                itemBuilder: (context) => [
                  if (!config.isReadOnly)
                    PopupMenuItem(
                      value: 'rename',
                      child: Text(t.settings.configurations.rename),
                    ),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: Text(t.settings.configurations.duplicate),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: Text(t.settings.configurations.exportToFiles),
                  ),
                  PopupMenuItem(
                    value: 'toggle_readonly',
                    child: Text(
                      config.isReadOnly
                          ? (t.settings.configurations.makeEditable)
                          : (t.settings.configurations.makeReadOnly),
                    ),
                  ),
                  if (configurations.length > 1 && !config.isReadOnly)
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        t.common.delete,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
