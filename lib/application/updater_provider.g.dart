// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'updater_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(updaterService)
final updaterServiceProvider = UpdaterServiceProvider._();

final class UpdaterServiceProvider
    extends $FunctionalProvider<UpdaterService, UpdaterService, UpdaterService>
    with $Provider<UpdaterService> {
  UpdaterServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updaterServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updaterServiceHash();

  @$internal
  @override
  $ProviderElement<UpdaterService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UpdaterService create(Ref ref) {
    return updaterService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdaterService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdaterService>(value),
    );
  }
}

String _$updaterServiceHash() => r'dc32a0887630a4c105a199030c4cac8bec9cfb1e';

@ProviderFor(UpdaterController)
final updaterControllerProvider = UpdaterControllerProvider._();

final class UpdaterControllerProvider
    extends $NotifierProvider<UpdaterController, UpdateState> {
  UpdaterControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updaterControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updaterControllerHash();

  @$internal
  @override
  UpdaterController create() => UpdaterController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateState>(value),
    );
  }
}

String _$updaterControllerHash() => r'aba409f45346738f1c883707c7ec537c8fbd09b9';

abstract class _$UpdaterController extends $Notifier<UpdateState> {
  UpdateState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<UpdateState, UpdateState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UpdateState, UpdateState>,
              UpdateState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
