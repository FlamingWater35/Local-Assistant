// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatHistory)
final chatHistoryProvider = ChatHistoryProvider._();

final class ChatHistoryProvider
    extends $NotifierProvider<ChatHistory, List<ChatSession>> {
  ChatHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatHistoryHash();

  @$internal
  @override
  ChatHistory create() => ChatHistory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ChatSession> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ChatSession>>(value),
    );
  }
}

String _$chatHistoryHash() => r'c36560df224dfb8df1b89c9ad1c0ae7c8453cf11';

abstract class _$ChatHistory extends $Notifier<List<ChatSession>> {
  List<ChatSession> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<ChatSession>, List<ChatSession>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ChatSession>, List<ChatSession>>,
              List<ChatSession>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ChatLogic)
final chatLogicProvider = ChatLogicProvider._();

final class ChatLogicProvider
    extends $NotifierProvider<ChatLogic, core.InMemoryChatController> {
  ChatLogicProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatLogicProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatLogicHash();

  @$internal
  @override
  ChatLogic create() => ChatLogic();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(core.InMemoryChatController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<core.InMemoryChatController>(value),
    );
  }
}

String _$chatLogicHash() => r'c960bdd4770b7f8a62dfcf680ed5d3feead979ba';

abstract class _$ChatLogic extends $Notifier<core.InMemoryChatController> {
  core.InMemoryChatController build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<core.InMemoryChatController, core.InMemoryChatController>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                core.InMemoryChatController,
                core.InMemoryChatController
              >,
              core.InMemoryChatController,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
