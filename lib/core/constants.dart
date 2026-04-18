import '../domain/models.dart';

class AppConstants {
  static const double contextThresholdRatio = 0.8;
  static const int defaultMaxContextWindow = 8192;
  static const int maxAttachments = 2;
  static const double tokenCharacterEstimate = 3.5;
  static const int tokensPerMedia = 256;

  static int estimateTokens(String text) {
    if (text.isEmpty) return 0;
    return (text.length / tokenCharacterEstimate).ceil();
  }

  static int estimateAttachmentTokens(List<ChatAttachment> attachments) {
    int tokens = 0;
    for (final att in attachments) {
      if (att.type == 'photo' || att.type == 'audio') {
        tokens += tokensPerMedia;
      }
      if (att.type == 'doc' && att.textContent != null) {
        tokens += estimateTokens(att.textContent!);
      }
    }
    return tokens;
  }

  static int estimateLocalAttachmentTokens(List<LocalAttachment>? attachments) {
    int tokens = 0;
    if (attachments == null) return tokens;
    for (final att in attachments) {
      if (att.type == 'photo' || att.type == 'audio') {
        tokens += tokensPerMedia;
      }
      if (att.type == 'doc' && att.textContent != null) {
        tokens += estimateTokens(att.textContent!);
      }
    }
    return tokens;
  }
}

enum ModelState { uninitialized, loading, ready, error, unloading }
