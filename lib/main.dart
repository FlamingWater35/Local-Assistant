import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_assistant/core/constants.dart';
import 'package:local_assistant/i18n/generated/translations.g.dart';

import 'application/settings_provider.dart';
import 'core/logger.dart';
import 'infrastructure/hive_service.dart';
import 'infrastructure/llm_service.dart';
import 'router/app_router.dart';

// Main entry point for the Local Assistant app.
// Initializes core services (Hive, Gemma) and sets up global error handling
// to ensure uncaught exceptions don't crash the app silently.
void main() async {
  // Ensures Flutter binding is initialized before running async code
  WidgetsFlutterBinding.ensureInitialized();

  // Catches uncaught async errors globally to prevent silent crashes
  runZonedGuarded(
    () async {
      FlutterGemma.initialize();
      final hiveService = HiveService();

      try {
        await hiveService.init();
      } catch (e, st) {
        appLogger.e(
          "Fatal: Failed to initialize Hive",
          error: e,
          stackTrace: st,
        );
        rethrow; // Fatal error, app cannot function without database
      }

      final settings = hiveService.getSettings();
      if (settings.locale.isEmpty) {
        LocaleSettings.useDeviceLocale();
      } else {
        try {
          LocaleSettings.setLocaleRaw(settings.locale);
        } catch (_) {
          // Fallback to device locale if saved locale is invalid or unsupported
          LocaleSettings.useDeviceLocale();
        }
      }

      runApp(
        ProviderScope(
          overrides: [hiveServiceProvider.overrideWithValue(hiveService)],
          child: TranslationProvider(child: const GemmaChatApp()),
        ),
      );
    },
    (error, stack) {
      appLogger.e("Uncaught async error", error: error, stackTrace: stack);
    },
  );
}

// Root widget for the application.
// Manages app lifecycle states to pause/resume the LLM model and free memory.
class GemmaChatApp extends ConsumerStatefulWidget {
  const GemmaChatApp({super.key});

  @override
  ConsumerState<GemmaChatApp> createState() => _GemmaChatAppState();
}

class _GemmaChatAppState extends ConsumerState<GemmaChatApp>
    with WidgetsBindingObserver {
  final _appRouter = AppRouter();
  bool _isResuming = false;

  // Handles app lifecycle changes to manage LLM memory usage.
  // Re-initializes the model when the app resumes if it was unloaded.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // Currently keeping model in memory for faster resume
        break;
      case AppLifecycleState.resumed:
        if (_isResuming) return;
        _isResuming = true;
        appLogger.i("App resumed: Checking model state...");

        final settings = ref.read(settingsControllerProvider);
        final modelStatus = ref.read(modelStatusProvider);

        if (modelStatus != ModelState.ready) {
          appLogger.i("Model not ready, reinitializing...");
          ref
              .read(llmServiceProvider)
              .initModel(settings)
              .then((_) {
                ref.read(llmServiceProvider).markSessionReady();
              })
              .catchError((e, st) {
                appLogger.e(
                  "Failed to restore model after resume",
                  error: e,
                  stackTrace: st,
                );
              })
              .whenComplete(() {
                _isResuming = false;
              });
        } else {
          _isResuming = false;
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
      case AppLifecycleState.detached:
        appLogger.i("App detached: Final cleanup");
        unawaited(ref.read(llmServiceProvider).unloadModel());
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

  // Builds the root MaterialApp with routing, theming, and localization.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: t.appTitle,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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

// Helper to fire-and-forget futures while ensuring errors are logged.
// Prevents unhandled async errors from crashing the app.
Future<void> unawaited(Future<void> future) {
  return future.catchError((error, stackTrace) {
    appLogger.e("Unawaited future error", error: error, stackTrace: stackTrace);
  });
}
