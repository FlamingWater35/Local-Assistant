import '../domain/models.dart';

class AppConstants {
  static const double contextThresholdRatio = 0.8;
  static const int maxContextWindow = 16384;
  static const int maxAttachments = 2;
  static const double tokenCharacterEstimate = 3.5;
  static const int tokensPerMedia = 256;
  static const List<int> _standardRamTiers = [2, 4, 6, 8, 12, 16, 24, 32];

  static const Map<int, int> _safeTokenLimits = {
    2: 1024,
    4: 2048,
    6: 4096,
    8: 8192,
    12: 12288,
    16: 16384,
  };

  static bool isMemorySafe(double reportedRamGb, int requestedTokens) {
    final hardwareTier = _standardRamTiers.firstWhere(
      (tier) => tier >= reportedRamGb,
      orElse: () => reportedRamGb.toInt(),
    );

    final safeLimit = _safeTokenLimits[hardwareTier] ?? 1024;

    return requestedTokens <= safeLimit;
  }

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
