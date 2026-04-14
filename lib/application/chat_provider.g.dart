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

String _$chatHistoryHash() => r'8fdeec7a7362f3a98cc3f2da0c56edf8d383933d';

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

String _$chatLogicHash() => r'decd8dcf2ea4ac85246f48c26e7ead188e933f8d';

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
