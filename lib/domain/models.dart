import 'package:flutter_chat_core/flutter_chat_core.dart' as core;
import 'package:hive_ce/hive.dart';

part 'models.g.dart';

class AvailableModel {
  const AvailableModel({
    required this.id,
    required this.name,
    required this.url,
    required this.fileName,
    required this.requiresAuth,
  });

  final String fileName;
  final String id;
  final String name;
  final bool requiresAuth;
  final String url;
}

const List<AvailableModel> kAvailableModels = [
  AvailableModel(
    id: 'gemma-3n-2b',
    name: 'Gemma 3n 2B (INT4)',
    url:
        'https://huggingface.co/google/gemma-3n-E2B-it-litert-preview/resolve/main/gemma-3n-E2B-it-int4.task',
    fileName: 'gemma-3n-E2B-it-int4.task',
    requiresAuth: true,
  ),
  AvailableModel(
    id: 'gemma-4-e2b',
    name: 'Gemma 4 E2B (INT4)',
    url:
        'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
    fileName: 'gemma-4-E2B-it.litertlm',
    requiresAuth: false,
  ),
];

@HiveType(typeId: 0)
class AppSettings extends HiveObject {
  AppSettings({
    this.selectedModel = 'gemma-3n-2b',
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.systemPrompt = 'You are a helpful AI assistant.',
    this.hfToken = '',
    this.enableGlobalMemory = false,
  });

  @HiveField(5, defaultValue: false)
  final bool enableGlobalMemory;

  @HiveField(4, defaultValue: '')
  final String hfToken;

  @HiveField(2, defaultValue: 2048)
  final int maxTokens;

  @HiveField(0, defaultValue: 'gemma-3n-2b')
  final String selectedModel;

  @HiveField(3, defaultValue: 'You are a helpful AI assistant.')
  final String systemPrompt;

  @HiveField(1, defaultValue: 0.7)
  final double temperature;

  AppSettings copyWith({
    String? selectedModel,
    double? temperature,
    int? maxTokens,
    String? systemPrompt,
    String? hfToken,
    bool? enableGlobalMemory,
  }) {
    return AppSettings(
      selectedModel: selectedModel ?? this.selectedModel,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      hfToken: hfToken ?? this.hfToken,
      enableGlobalMemory: enableGlobalMemory ?? this.enableGlobalMemory,
    );
  }
}

@HiveType(typeId: 1)
class LocalChatMessage extends HiveObject {
  LocalChatMessage({
    required this.id,
    required this.text,
    required this.authorId,
    required this.createdAt,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
  });

  @HiveField(2)
  final String authorId;

  @HiveField(3)
  final int createdAt;

  @HiveField(6)
  final String? fileName;

  @HiveField(7)
  final int? fileSize;

  @HiveField(5)
  final String? fileUrl;

  @HiveField(0)
  final String id;

  @HiveField(4)
  final String? imageUrl;

  @HiveField(8)
  final String? mimeType;

  @HiveField(1)
  final String text;

  core.Message toChatCoreType() {
    if (imageUrl != null) {
      return core.ImageMessage(
        id: id,
        authorId: authorId,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true),
        source: imageUrl!,
        text: text.isEmpty ? null : text,
      );
    }
    if (fileUrl != null) {
      return core.FileMessage(
        id: id,
        authorId: authorId,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true),
        name: fileName ?? 'Attachment',
        size: fileSize ?? 0,
        source: fileUrl!,
        mimeType: mimeType,
      );
    }
    return core.TextMessage(
      id: id,
      text: text,
      authorId: authorId,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt, isUtc: true),
    );
  }
}

@HiveType(typeId: 2)
class ChatSession extends HiveObject {
  ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.messages,
  });

  @HiveField(0)
  final String id;

  @HiveField(3)
  final List<LocalChatMessage> messages;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final int updatedAt;

  ChatSession copyWith({
    String? title,
    int? updatedAt,
    List<LocalChatMessage>? messages,
  }) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}
