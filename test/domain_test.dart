// Unit tests for the domain layer. These run fully offline — no LLM,
// no network, no Hive platform channels — and cover the pure logic the
// upgrade touched: settings round-tripping, token estimation, chat-message
// persistence mapping, and model metadata.

import 'dart:typed_data';

import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_assistant/core/constants.dart';
import 'package:local_assistant/domain/models.dart';

void main() {
  group('SettingConfiguration', () {
    test('round-trips through JSON', () {
      const original = SettingConfiguration(
        id: 'cfg-1',
        name: 'Creative',
        selectedModel: 'gemma-4-e2b',
        temperature: 0.9,
        maxTokens: 2048,
        systemPrompt: 'Be creative.',
        enableThinking: true,
        selectedBackend: PreferredBackend.npu,
        enableGlobalMemory: true,
        isReadOnly: false,
      );

      final restored = SettingConfiguration.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.selectedModel, original.selectedModel);
      expect(restored.temperature, original.temperature);
      expect(restored.maxTokens, original.maxTokens);
      expect(restored.systemPrompt, original.systemPrompt);
      expect(restored.enableThinking, original.enableThinking);
      expect(restored.selectedBackend, PreferredBackend.npu);
      expect(restored.enableGlobalMemory, original.enableGlobalMemory);
      expect(restored.isReadOnly, original.isReadOnly);
    });

    test('fromJson applies defaults for missing keys', () {
      final restored = SettingConfiguration.fromJson(const {});
      expect(restored.id, '');
      expect(restored.name, 'Default');
      expect(restored.selectedModel, 'gemma-4-e2b');
      expect(restored.temperature, 0.7);
      expect(restored.maxTokens, 4096);
      expect(restored.selectedBackend, PreferredBackend.gpu);
    });

    test('applyToSettings carries values into AppSettings', () {
      const config = SettingConfiguration(
        id: 'cfg-2',
        name: 'Focused',
        temperature: 0.2,
        maxTokens: 1024,
        systemPrompt: 'Be terse.',
        enableThinking: true,
        selectedBackend: PreferredBackend.cpu,
        enableGlobalMemory: true,
      );

      final base = AppSettings();
      final applied = config.applyToSettings(base);

      expect(applied.temperature, 0.2);
      expect(applied.maxTokens, 1024);
      expect(applied.systemPrompt, 'Be terse.');
      expect(applied.enableThinking, isTrue);
      expect(applied.selectedBackend, PreferredBackend.cpu);
      expect(applied.enableGlobalMemory, isTrue);
    });
  });

  group('AppConstants.estimateTokens', () {
    test('empty text is zero', () {
      expect(AppConstants.estimateTokens(''), 0);
    });

    test('scales with character count', () {
      // "abc" -> ceil(3 / 3.5) = 1
      expect(AppConstants.estimateTokens('abc'), 1);
      // 35 chars -> ceil(35 / 3.5) = 10
      expect(AppConstants.estimateTokens('a' * 35), 10);
    });

    test('attachment token estimates', () {
      final photo = ChatAttachment(
        type: 'photo',
        bytes: Uint8List.fromList(List.filled(100, 0)),
        url: 'x',
        fileName: 'p.jpg',
        mimeType: 'image/jpeg',
      );
      expect(AppConstants.estimateAttachmentTokens([photo]), 256);

      final doc = ChatAttachment(
        type: 'doc',
        bytes: Uint8List.fromList(List.filled(10, 0)),
        url: 'y',
        fileName: 'd.txt',
        mimeType: 'text/plain',
        textContent: 'a' * 35,
      );
      expect(AppConstants.estimateAttachmentTokens([doc]), 10);
    });
  });

  group('LocalChatMessage.toChatCoreType', () {
    test('plain AI text becomes a TextMessage', () {
      final msg = LocalChatMessage(
        id: 'm1',
        text: 'Hello there',
        authorId: 'ai',
        createdAt: 1_700_000_000_000,
      );
      final coreMsg = msg.toChatCoreType();
      expect(coreMsg, isA<core.TextMessage>());
      expect((coreMsg as core.TextMessage).text, 'Hello there');
    });

    test('thinking-wrapped AI text extracts thinking into metadata', () {
      const thinking = 'Let me reason about this.';
      final msg = LocalChatMessage(
        id: 'm2',
        text:
            '<local_assistant_thinking>\n$thinking\n</local_assistant_thinking>\nAnswer text',
        authorId: 'ai',
        createdAt: 1_700_000_000_000,
      );
      final coreMsg = msg.toChatCoreType();
      expect(coreMsg, isA<core.CustomMessage>());
      final custom = coreMsg as core.CustomMessage;
      expect(custom.metadata?['text'], 'Answer text');
      expect(custom.metadata?['thinking'], thinking);
    });

    test('user messages always map to CustomMessage with metadata', () {
      final msg = LocalChatMessage(
        id: 'm3',
        text: 'Hi',
        authorId: 'user',
        createdAt: 1_700_000_000_000,
      );
      final coreMsg = msg.toChatCoreType();
      expect(coreMsg, isA<core.CustomMessage>());
      expect((coreMsg as core.CustomMessage).metadata?['text'], 'Hi');
    });
  });

  group('ChatSession', () {
    test('copyWith updates fields without mutating', () {
      final msg = LocalChatMessage(
        id: 'm',
        text: 't',
        authorId: 'user',
        createdAt: 1,
      );
      final session = ChatSession(
        id: 's1',
        title: 'Old',
        updatedAt: 1,
        messages: [msg],
      );

      final updated = session.copyWith(title: 'New', updatedAt: 2);

      expect(session.title, 'Old');
      expect(updated.title, 'New');
      expect(updated.updatedAt, 2);
      expect(updated.messages, [msg]);
    });
  });
}
