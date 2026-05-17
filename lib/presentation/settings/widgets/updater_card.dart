import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:local_assistant/application/updater_provider.dart';
import 'package:local_assistant/i18n/generated/translations.g.dart';

class UpdaterCard extends ConsumerWidget {
  const UpdaterCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final updateState = ref.watch(updaterControllerProvider);
    final updaterNotifier = ref.read(updaterControllerProvider.notifier);
    final theme = Theme.of(context);

    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: switch (updateState) {
          UpdateInitial() => ListTile(
            leading: const Icon(Icons.update),
            title: Text(t.settings.checkForUpdates),
            onTap: updaterNotifier.checkForUpdate,
          ),
          UpdateChecking() => ListTile(
            leading: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text(t.settings.checkingForUpdates),
          ),
          UpdateNotAvailable() => ListTile(
            leading: Icon(
              Icons.check_circle_outline,
              color: theme.colorScheme.primary,
            ),
            title: Text(t.settings.appUpToDate),
            subtitle: Text(t.settings.latestVersion),
            onTap: updaterNotifier.checkForUpdate,
          ),
          UpdateAvailable(info: final info) => Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.download_for_offline_outlined,
                  color: theme.colorScheme.secondary,
                ),
                title: Text(t.settings.updateAvailable(version: info.version)),
                subtitle: Text(t.settings.tapToDownload),
                onTap: updaterNotifier.downloadUpdate,
              ),
              if (info.releaseNotes != null && info.releaseNotes!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Card(
                    margin: EdgeInsets.zero,
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      shape: const Border(),
                      title: Text(
                        t.settings.releaseNotes,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.all(12.0),
                      children: [GptMarkdown(info.releaseNotes!)],
                    ),
                  ),
                ),
            ],
          ),
          UpdateDownloading(progress: final progress) => ListTile(
            title: Text(t.settings.downloadingUpdate),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.settings.percentComplete(
                      percent: (progress * 100).toStringAsFixed(0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          UpdateError(message: final message) => ListTile(
            leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
            title: Text(t.settings.updateCheckFailed),
            subtitle: Text(message),
            onTap: updaterNotifier.checkForUpdate,
          ),
        },
      ),
    );
  }
}
