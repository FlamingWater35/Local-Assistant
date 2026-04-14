// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'llm_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(llmService)
final llmServiceProvider = LlmServiceProvider._();

final class LlmServiceProvider
    extends $FunctionalProvider<LlmService, LlmService, LlmService>
    with $Provider<LlmService> {
  LlmServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'llmServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$llmServiceHash();

  @$internal
  @override
  $ProviderElement<LlmService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LlmService create(Ref ref) {
    return llmService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LlmService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LlmService>(value),
    );
  }
}

String _$llmServiceHash() => r'3f0524f014c81b949600b3c90e80c27ad145c3fc';
