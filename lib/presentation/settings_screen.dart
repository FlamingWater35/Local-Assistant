import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/model_manager_provider.dart';
import '../application/settings_provider.dart';
import '../domain/models.dart';
import '../router/app_router.dart';

@RoutePage()
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late AppSettings _draftSettings;

  @override
  void initState() {
    super.initState();
    _draftSettings = ref.read(settingsControllerProvider);
  }

  void _showDownloadDialog(AvailableModel model) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DownloadDialog(
        model: model,
        currentSettings: _draftSettings,
        onDownloaded: () {
          setState(() {
            _draftSettings = _draftSettings.copyWith(selectedModel: model.id);
          });
        },
      ),
    ).then((_) => setState(() {}));
  }

  Future<void> _saveAndLoad() async {
    final isInstalled = await ref.read(
      isModelInstalledProvider(_draftSettings.selectedModel).future,
    );
    if (!isInstalled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected model is not downloaded!')),
        );
      }
      return;
    }

    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .updateSettings(_draftSettings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings applied successfully!')),
        );
        if (context.router.canPop()) {
          context.router.back();
        } else {
          context.router.replace(const ChatRoute());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Available Models',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          ...kAvailableModels.map((model) {
            final isInstalledAsync = ref.watch(
              isModelInstalledProvider(model.id),
            );
            return Card(
              child: ListTile(
                title: Text(model.name),
                subtitle: isInstalledAsync.when(
                  data: (installed) => Text(
                    installed ? "Ready to use" : "Not downloaded",
                    style: TextStyle(
                      color: installed ? Colors.green : Colors.grey,
                    ),
                  ),
                  loading: () => const Text("Checking status..."),
                  error: (_, _) => const Text("Error checking status"),
                ),
                trailing: isInstalledAsync.value == true
                    ? Radio<String>(
                        value: model.id,
                        groupValue: _draftSettings.selectedModel,
                        onChanged: (val) => setState(
                          () => _draftSettings = _draftSettings.copyWith(
                            selectedModel: val,
                          ),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () => _showDownloadDialog(model),
                      ),
              ),
            );
          }),

          const SizedBox(height: 30),
          Text(
            'Inference & Memory',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text("Enable Memory Across Chats"),
            subtitle: const Text(
              "Allows the AI to silently reference facts from your other recent conversations.",
            ),
            value: _draftSettings.enableGlobalMemory,
            onChanged: (val) => setState(
              () => _draftSettings = _draftSettings.copyWith(
                enableGlobalMemory: val,
              ),
            ),
          ),
          const Divider(),

          ListTile(
            title: const Text("Context Limit (Memory Size)"),
            subtitle: Text(
              "Keep the last ${_draftSettings.contextLimit} messages in memory per chat.\nLower this to save RAM and prevent overflow.",
            ),
          ),
          Slider(
            value: _draftSettings.contextLimit.toDouble(),
            min: 2,
            max: 100,
            divisions: 49,
            label: _draftSettings.contextLimit.toString(),
            onChanged: (val) => setState(
              () => _draftSettings = _draftSettings.copyWith(
                contextLimit: val.toInt(),
              ),
            ),
          ),

          ListTile(
            title: const Text("Max Output Length (Tokens)"),
            subtitle: Text("Current limit: ${_draftSettings.maxTokens} tokens"),
          ),
          Slider(
            value: _draftSettings.maxTokens.toDouble(),
            min: 256,
            max: 4096,
            divisions: 15,
            label: _draftSettings.maxTokens.toString(),
            onChanged: (val) => setState(
              () => _draftSettings = _draftSettings.copyWith(
                maxTokens: val.toInt(),
              ),
            ),
          ),

          ListTile(
            title: const Text("Temperature"),
            subtitle: Text(
              "Creativity level: ${_draftSettings.temperature.toStringAsFixed(2)}",
            ),
          ),
          Slider(
            value: _draftSettings.temperature,
            min: 0.0,
            max: 1.0,
            onChanged: (val) => setState(
              () => _draftSettings = _draftSettings.copyWith(temperature: val),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton(
            onPressed: _saveAndLoad,
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('Save & Apply', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadDialog extends ConsumerStatefulWidget {
  const _DownloadDialog({
    required this.model,
    required this.currentSettings,
    required this.onDownloaded,
  });

  final AppSettings currentSettings;
  final AvailableModel model;
  final VoidCallback onDownloaded;

  @override
  ConsumerState<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends ConsumerState<_DownloadDialog> {
  String? _error;
  int? _progress;
  late TextEditingController _tokenController;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(
      text: widget.currentSettings.hfToken,
    );
  }

  Future<void> _startDownload() async {
    if (widget.model.requiresAuth && _tokenController.text.trim().isEmpty) {
      setState(() => _error = "HuggingFace Token required.");
      return;
    }

    setState(() {
      _progress = 0;
      _error = null;
    });

    try {
      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
          .fromNetwork(widget.model.url, token: _tokenController.text.trim())
          .withProgress((p) {
            if (mounted) setState(() => _progress = p);
          })
          .install();

      final settingsNotifier = ref.read(settingsControllerProvider.notifier);
      await settingsNotifier.updateSettings(
        widget.currentSettings.copyWith(hfToken: _tokenController.text.trim()),
        reloadModel: false,
      );

      ref.invalidate(isModelInstalledProvider(widget.model.id));
      widget.onDownloaded();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Download ${widget.model.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.model.requiresAuth) ...[
            const Text(
              "This model requires HuggingFace access.",
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'HuggingFace Token',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enabled: _progress == null,
            ),
          ],
          const SizedBox(height: 20),
          if (_progress != null) ...[
            LinearProgressIndicator(value: _progress! / 100),
            const SizedBox(height: 10),
            Text('Downloading... $_progress%'),
          ],
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
        ],
      ),
      actions: [
        if (_progress == null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        if (_progress == null)
          ElevatedButton(
            onPressed: _startDownload,
            child: const Text('Start Download'),
          ),
      ],
    );
  }
}
