import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stream_manager_provider.g.dart';

class StreamMessageState {
  const StreamMessageState({this.text = '', this.thinking = ''});

  final String text;
  final String thinking;

  StreamMessageState copyWith({String? text, String? thinking}) {
    return StreamMessageState(
      text: text ?? this.text,
      thinking: thinking ?? this.thinking,
    );
  }
}

@Riverpod(keepAlive: true)
class ChatStreamManager extends _$ChatStreamManager {
  String getText(String id) => state[id]?.text ?? '';

  String getThinking(String id) => state[id]?.thinking ?? '';

  void startStream(String id) {
    state = {...state, id: const StreamMessageState()};
  }

  void addChunk(String id, {String? text, String? thinking}) {
    final current = state[id] ?? const StreamMessageState();
    state = {
      ...state,
      id: StreamMessageState(
        text: current.text + (text ?? ''),
        thinking: current.thinking + (thinking ?? ''),
      ),
    };
  }

  void cleanup(String id) {
    if (!state.containsKey(id)) return;
    final newState = Map.of(state);
    newState.remove(id);
    state = newState;
  }

  @override
  Map<String, StreamMessageState> build() {
    return {};
  }
}
