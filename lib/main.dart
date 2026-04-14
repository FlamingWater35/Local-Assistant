import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/settings_provider.dart';
import 'core/logger.dart';
import 'infrastructure/hive_service.dart';
import 'infrastructure/llm_service.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterGemma.initialize();

  final hiveService = HiveService();
  await hiveService.init();

  runApp(
    ProviderScope(
      overrides: [hiveServiceProvider.overrideWithValue(hiveService)],
      child: const GemmaChatApp(),
    ),
  );
}

class GemmaChatApp extends ConsumerStatefulWidget {
  const GemmaChatApp({super.key});

  @override
  ConsumerState<GemmaChatApp> createState() => _GemmaChatAppState();
}

class _GemmaChatAppState extends ConsumerState<GemmaChatApp>
    with WidgetsBindingObserver {
  final _appRouter = AppRouter();
  bool _isResuming = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        appLogger.w("App paused: Freeing memory...");
        unawaited(ref.read(llmServiceProvider).unloadModel());
        break;

      case AppLifecycleState.resumed:
        if (_isResuming) return;
        _isResuming = true;

        appLogger.i("App resumed: Restoring model...");
        final settings = ref.read(settingsControllerProvider);
        ref
            .read(llmServiceProvider)
            .initModel(settings)
            .then((_) {
              ref.read(llmServiceProvider).markSessionReady();
            })
            .catchError((e) {
              appLogger.e("Failed to restore model after resume", error: e);
            })
            .whenComplete(() {
              _isResuming = false;
            });
        break;

      case AppLifecycleState.inactive:
        break;

      case AppLifecycleState.detached:
        appLogger.i("App detached: Final cleanup");
        unawaited(ref.read(llmServiceProvider).unloadModel());
        break;

      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(ref.read(llmServiceProvider).unloadModel());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Local Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routerConfig: _appRouter.config(),
    );
  }
}

Future<void> unawaited(Future<void> future) {
  return future.catchError((error, stackTrace) {
    appLogger.e("Unawaited future error", error: error, stackTrace: stackTrace);
  });
}
