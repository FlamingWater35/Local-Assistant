// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_manager_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(isModelInstalled)
final isModelInstalledProvider = IsModelInstalledFamily._();

final class IsModelInstalledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  IsModelInstalledProvider._({
    required IsModelInstalledFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isModelInstalledProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isModelInstalledHash();

  @override
  String toString() {
    return r'isModelInstalledProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return isModelInstalled(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IsModelInstalledProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isModelInstalledHash() => r'f14e677fd08f742d4994180dedf7158bef26d4c0';

final class IsModelInstalledFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  IsModelInstalledFamily._()
    : super(
        retry: null,
        name: r'isModelInstalledProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IsModelInstalledProvider call(String modelId) =>
      IsModelInstalledProvider._(argument: modelId, from: this);

  @override
  String toString() => r'isModelInstalledProvider';
}

@ProviderFor(ModelDownloader)
final modelDownloaderProvider = ModelDownloaderProvider._();

final class ModelDownloaderProvider
    extends $NotifierProvider<ModelDownloader, AsyncValue<int?>> {
  ModelDownloaderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'modelDownloaderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$modelDownloaderHash();

  @$internal
  @override
  ModelDownloader create() => ModelDownloader();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<int?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<int?>>(value),
    );
  }
}

String _$modelDownloaderHash() => r'b9c63d28670bcb458230b96f9400f0976c7b2d17';

abstract class _$ModelDownloader extends $Notifier<AsyncValue<int?>> {
  AsyncValue<int?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int?>, AsyncValue<int?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int?>, AsyncValue<int?>>,
              AsyncValue<int?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
