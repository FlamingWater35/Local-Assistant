///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'translations.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// en: 'Local Assistant'
	String get appTitle => 'Local Assistant';

	late final TranslationsChatEn chat = TranslationsChatEn.internal(_root);
	late final TranslationsAttachmentsEn attachments = TranslationsAttachmentsEn.internal(_root);
	late final TranslationsSettingsEn settings = TranslationsSettingsEn.internal(_root);
	late final TranslationsSetupEn setup = TranslationsSetupEn.internal(_root);
	late final TranslationsDownloadEn download = TranslationsDownloadEn.internal(_root);
	late final TranslationsErrorsEn errors = TranslationsErrorsEn.internal(_root);
	late final TranslationsCommonEn common = TranslationsCommonEn.internal(_root);
}

// Path: chat
class TranslationsChatEn {
	TranslationsChatEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Local AI Assistant'
	String get title => 'Local AI Assistant';

	/// en: 'New Chat'
	String get newChat => 'New Chat';

	/// en: 'Recent History'
	String get recentHistory => 'Recent History';

	/// en: 'Settings & Models'
	String get settingsAndModels => 'Settings & Models';

	/// en: 'Assistant'
	String get assistantName => 'Assistant';

	/// en: 'Me'
	String get userName => 'Me';

	/// en: 'Local AI'
	String get aiName => 'Local AI';

	/// en: 'Delete Chat'
	String get deleteChatTitle => 'Delete Chat';

	/// en: 'Are you sure you want to delete "$title"? This cannot be undone.'
	String deleteChatConfirm({required Object title}) => 'Are you sure you want to delete "${title}"?\nThis cannot be undone.';

	/// en: 'Delete Message'
	String get deleteMessageTitle => 'Delete Message';

	/// en: 'Are you sure you want to delete this entire message and its attachments?'
	String get deleteMessageConfirm => 'Are you sure you want to delete this entire message and its attachments?';

	/// en: 'Chat deleted'
	String get chatDeleted => 'Chat deleted';

	/// en: 'Message deleted'
	String get messageDeleted => 'Message deleted';

	/// en: 'Maximum of 2 attachments allowed per message.'
	String get maxAttachments => 'Maximum of 2 attachments allowed per message.';

	/// en: 'Copy message'
	String get copyMessage => 'Copy message';

	/// en: 'Copied to clipboard'
	String get copiedToClipboard => 'Copied to clipboard';

	/// en: 'Delete message'
	String get deleteMessage => 'Delete message';

	/// en: 'Delete message group'
	String get deleteMessageGroup => 'Delete message group';

	/// en: 'Compose Prompt'
	String get composePrompt => 'Compose Prompt';

	/// en: 'Send'
	String get send => 'Send';

	/// en: 'Write your detailed prompt here...'
	String get writePromptHint => 'Write your detailed prompt here...';

	/// en: 'Message Local Assistant...'
	String get messageHint => 'Message Local Assistant...';

	/// en: 'Attachment session'
	String get attachmentSession => 'Attachment session';

	/// en: 'Generating...'
	String get generating => 'Generating...';

	/// en: 'Stop'
	String get stop => 'Stop';
}

// Path: attachments
class TranslationsAttachmentsEn {
	TranslationsAttachmentsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Photo'
	String get photo => 'Photo';

	/// en: 'Audio (.wav)'
	String get audio => 'Audio (.wav)';

	/// en: 'Document (.txt, .md, .csv)'
	String get document => 'Document (.txt, .md, .csv)';
}

// Path: settings
class TranslationsSettingsEn {
	TranslationsSettingsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Settings'
	String get title => 'Settings';

	/// en: 'General'
	String get general => 'General';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'System Default'
	String get systemLanguage => 'System Default';

	/// en: 'AI Models'
	String get aiModels => 'AI Models';

	/// en: 'Inference & Memory'
	String get inferenceAndMemory => 'Inference & Memory';

	/// en: 'Behavior'
	String get behavior => 'Behavior';

	/// en: 'App Update'
	String get appUpdate => 'App Update';

	/// en: 'Ready to use'
	String get readyToUse => 'Ready to use';

	/// en: 'Not downloaded'
	String get notDownloaded => 'Not downloaded';

	/// en: 'Checking status...'
	String get checkingStatus => 'Checking status...';

	/// en: 'Error checking status'
	String get errorCheckingStatus => 'Error checking status';

	/// en: 'Delete Model'
	String get deleteModelTitle => 'Delete Model';

	/// en: 'Are you sure you want to delete $name? You will have to download it again to use it.'
	String deleteModelConfirm({required Object name}) => 'Are you sure you want to delete ${name}? You will have to download it again to use it.';

	/// en: 'Model deleted successfully'
	String get modelDeleted => 'Model deleted successfully';

	/// en: 'Apply Changes'
	String get applyChanges => 'Apply Changes';

	/// en: 'Settings applied successfully'
	String get settingsApplied => 'Settings applied successfully';

	/// en: 'Selected model is not downloaded!'
	String get modelNotDownloaded => 'Selected model is not downloaded!';

	/// en: 'Error: $details'
	String errorWithDetails({required Object details}) => 'Error: ${details}';

	/// en: 'Enable Memory Across Chats'
	String get enableMemoryTitle => 'Enable Memory Across Chats';

	/// en: 'Allows the AI to silently reference facts from your other recent conversations.'
	String get enableMemorySubtitle => 'Allows the AI to silently reference facts from your other recent conversations.';

	/// en: 'Total Context Window'
	String get totalContextWindow => 'Total Context Window';

	/// en: 'Hardware memory for Input + Output. Smart Truncation will automatically prune older messages when the limit is reached.'
	String get contextWindowDescription => 'Hardware memory for Input + Output. Smart Truncation will automatically prune older messages when the limit is reached.';

	/// en: 'Tokens'
	String get tokens => 'Tokens';

	/// en: 'Temperature'
	String get temperature => 'Temperature';

	/// en: 'Controls creativity. Lower is more focused, higher is more random.'
	String get temperatureDescription => 'Controls creativity. Lower is more focused, higher is more random.';

	/// en: 'System Instructions'
	String get systemInstructions => 'System Instructions';

	/// en: 'Custom instructions to guide the AI's overall behavior and persona.'
	String get systemInstructionsDescription => 'Custom instructions to guide the AI\'s overall behavior and persona.';

	/// en: 'You are a helpful AI assistant.'
	String get systemInstructionsHint => 'You are a helpful AI assistant.';

	/// en: 'Reset to Defaults'
	String get resetDefaults => 'Reset to Defaults';

	/// en: 'Are you sure you want to reset all inference and behavior settings? Your downloaded models and language preference will not be affected.'
	String get resetConfirm => 'Are you sure you want to reset all inference and behavior settings? Your downloaded models and language preference will not be affected.';

	/// en: 'Settings reset to defaults'
	String get resetSuccess => 'Settings reset to defaults';

	/// en: 'Check for updates'
	String get checkForUpdates => 'Check for updates';

	/// en: 'Checking for updates...'
	String get checkingForUpdates => 'Checking for updates...';

	/// en: 'App is up to date'
	String get appUpToDate => 'App is up to date';

	/// en: 'You are using the latest version'
	String get latestVersion => 'You are using the latest version';

	/// en: 'Update available: v$version'
	String updateAvailable({required Object version}) => 'Update available: v${version}';

	/// en: 'A new app update (v$version) is available. Check Settings to install.'
	String updateAvailableSnackbar({required Object version}) => 'A new app update (v${version}) is available. Check Settings to install.';

	/// en: 'Tap to download and install'
	String get tapToDownload => 'Tap to download and install';

	/// en: 'Release Notes'
	String get releaseNotes => 'Release Notes';

	/// en: 'Downloading update...'
	String get downloadingUpdate => 'Downloading update...';

	/// en: '$percent% complete'
	String percentComplete({required Object percent}) => '${percent}% complete';

	/// en: 'Update check failed'
	String get updateCheckFailed => 'Update check failed';

	/// en: 'Download Model'
	String get downloadModelTooltip => 'Download Model';

	late final TranslationsSettingsRamIndicatorEn ramIndicator = TranslationsSettingsRamIndicatorEn.internal(_root);
}

// Path: setup
class TranslationsSetupEn {
	TranslationsSetupEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Checking system state...'
	String get checkingSystem => 'Checking system state...';

	/// en: 'Starting AI Model...'
	String get startingModel => 'Starting AI Model...';

	/// en: 'Welcome to Local Assistant'
	String get welcomeTitle => 'Welcome to\nLocal Assistant';

	/// en: 'To get started, please download an AI model. All inference runs locally and privately on your device hardware.'
	String get welcomeSubtitle => 'To get started, please download an AI model. All inference runs locally and privately on your device hardware.';

	/// en: 'AVAILABLE MODELS'
	String get availableModels => 'AVAILABLE MODELS';

	/// en: 'Downloaded'
	String get downloaded => 'Downloaded';

	/// en: 'Tap to download'
	String get tapToDownload => 'Tap to download';

	/// en: 'Checking...'
	String get checking => 'Checking...';

	/// en: 'Error'
	String get error => 'Error';

	/// en: 'Get'
	String get get => 'Get';

	/// en: 'Start Chatting'
	String get startChatting => 'Start Chatting';
}

// Path: download
class TranslationsDownloadEn {
	TranslationsDownloadEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Download $name'
	String title({required Object name}) => 'Download ${name}';

	/// en: 'This model requires HuggingFace access.'
	String get requiresAuth => 'This model requires HuggingFace access.';

	/// en: 'HuggingFace Token'
	String get hfToken => 'HuggingFace Token';

	/// en: 'HuggingFace Token required.'
	String get hfTokenRequired => 'HuggingFace Token required.';

	/// en: 'Downloading... $progress%'
	String downloading({required Object progress}) => 'Downloading... ${progress}%';

	/// en: 'Start Download'
	String get startDownload => 'Start Download';

	/// en: 'No internet connection detected.'
	String get noInternet => 'No internet connection detected.';

	/// en: 'Large File Warning'
	String get mobileDataWarningTitle => 'Large File Warning';

	/// en: 'You are connected via Mobile Data. This model is a large file (approx 1-2GB) and downloading it may consume significant data or incur additional charges. Proceed anyway?'
	String get mobileDataWarning => 'You are connected via Mobile Data. This model is a large file (approx 1-2GB) and downloading it may consume significant data or incur additional charges. Proceed anyway?';

	/// en: 'Proceed'
	String get proceed => 'Proceed';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Model downloaded successfully!'
	String get downloadSuccess => 'Model downloaded successfully!';

	/// en: 'Download failed: $error'
	String downloadFailed({required Object error}) => 'Download failed: ${error}';
}

// Path: errors
class TranslationsErrorsEn {
	TranslationsErrorsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '⚠️ Error: The input exceeded strict hardware memory limits. The system attempted to prune memory but the prompt is too large. Please increase 'Total Context Window' in Settings or start a new chat.'
	String get contextOverflow => '⚠️ Error: The input exceeded strict hardware memory limits. The system attempted to prune memory but the prompt is too large. Please increase \'Total Context Window\' in Settings or start a new chat.';

	/// en: '⚠️ Error: Model inference failed. Details: $error'
	String inferenceFailed({required Object error}) => '⚠️ Error: Model inference failed.\nDetails: ${error}';

	/// en: '⚠️ Error: Failed to start generation. Details: $error'
	String generationFailed({required Object error}) => '⚠️ Error: Failed to start generation.\nDetails: ${error}';
}

// Path: common
class TranslationsCommonEn {
	TranslationsCommonEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: 'Recommended'
	String get recommended => 'Recommended';
}

// Path: settings.ramIndicator
class TranslationsSettingsRamIndicatorEn {
	TranslationsSettingsRamIndicatorEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Device RAM: Unknown'
	String get unknown => 'Device RAM: Unknown';

	/// en: 'Device RAM: $ram GB'
	String detected({required Object ram}) => 'Device RAM: ${ram} GB';

	/// en: '✅ Safe for your device's memory.'
	String get safe => '✅ Safe for your device\'s memory.';

	/// en: '⚠️ High risk of out-of-memory errors on this device.'
	String get warning => '⚠️ High risk of out-of-memory errors on this device.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appTitle' => 'Local Assistant',
			'chat.title' => 'Local AI Assistant',
			'chat.newChat' => 'New Chat',
			'chat.recentHistory' => 'Recent History',
			'chat.settingsAndModels' => 'Settings & Models',
			'chat.assistantName' => 'Assistant',
			'chat.userName' => 'Me',
			'chat.aiName' => 'Local AI',
			'chat.deleteChatTitle' => 'Delete Chat',
			'chat.deleteChatConfirm' => ({required Object title}) => 'Are you sure you want to delete "${title}"?\nThis cannot be undone.',
			'chat.deleteMessageTitle' => 'Delete Message',
			'chat.deleteMessageConfirm' => 'Are you sure you want to delete this entire message and its attachments?',
			'chat.chatDeleted' => 'Chat deleted',
			'chat.messageDeleted' => 'Message deleted',
			'chat.maxAttachments' => 'Maximum of 2 attachments allowed per message.',
			'chat.copyMessage' => 'Copy message',
			'chat.copiedToClipboard' => 'Copied to clipboard',
			'chat.deleteMessage' => 'Delete message',
			'chat.deleteMessageGroup' => 'Delete message group',
			'chat.composePrompt' => 'Compose Prompt',
			'chat.send' => 'Send',
			'chat.writePromptHint' => 'Write your detailed prompt here...',
			'chat.messageHint' => 'Message Local Assistant...',
			'chat.attachmentSession' => 'Attachment session',
			'chat.generating' => 'Generating...',
			'chat.stop' => 'Stop',
			'attachments.photo' => 'Photo',
			'attachments.audio' => 'Audio (.wav)',
			'attachments.document' => 'Document (.txt, .md, .csv)',
			'settings.title' => 'Settings',
			'settings.general' => 'General',
			'settings.language' => 'Language',
			'settings.systemLanguage' => 'System Default',
			'settings.aiModels' => 'AI Models',
			'settings.inferenceAndMemory' => 'Inference & Memory',
			'settings.behavior' => 'Behavior',
			'settings.appUpdate' => 'App Update',
			'settings.readyToUse' => 'Ready to use',
			'settings.notDownloaded' => 'Not downloaded',
			'settings.checkingStatus' => 'Checking status...',
			'settings.errorCheckingStatus' => 'Error checking status',
			'settings.deleteModelTitle' => 'Delete Model',
			'settings.deleteModelConfirm' => ({required Object name}) => 'Are you sure you want to delete ${name}? You will have to download it again to use it.',
			'settings.modelDeleted' => 'Model deleted successfully',
			'settings.applyChanges' => 'Apply Changes',
			'settings.settingsApplied' => 'Settings applied successfully',
			'settings.modelNotDownloaded' => 'Selected model is not downloaded!',
			'settings.errorWithDetails' => ({required Object details}) => 'Error: ${details}',
			'settings.enableMemoryTitle' => 'Enable Memory Across Chats',
			'settings.enableMemorySubtitle' => 'Allows the AI to silently reference facts from your other recent conversations.',
			'settings.totalContextWindow' => 'Total Context Window',
			'settings.contextWindowDescription' => 'Hardware memory for Input + Output. Smart Truncation will automatically prune older messages when the limit is reached.',
			'settings.tokens' => 'Tokens',
			'settings.temperature' => 'Temperature',
			'settings.temperatureDescription' => 'Controls creativity. Lower is more focused, higher is more random.',
			'settings.systemInstructions' => 'System Instructions',
			'settings.systemInstructionsDescription' => 'Custom instructions to guide the AI\'s overall behavior and persona.',
			'settings.systemInstructionsHint' => 'You are a helpful AI assistant.',
			'settings.resetDefaults' => 'Reset to Defaults',
			'settings.resetConfirm' => 'Are you sure you want to reset all inference and behavior settings? Your downloaded models and language preference will not be affected.',
			'settings.resetSuccess' => 'Settings reset to defaults',
			'settings.checkForUpdates' => 'Check for updates',
			'settings.checkingForUpdates' => 'Checking for updates...',
			'settings.appUpToDate' => 'App is up to date',
			'settings.latestVersion' => 'You are using the latest version',
			'settings.updateAvailable' => ({required Object version}) => 'Update available: v${version}',
			'settings.updateAvailableSnackbar' => ({required Object version}) => 'A new app update (v${version}) is available. Check Settings to install.',
			'settings.tapToDownload' => 'Tap to download and install',
			'settings.releaseNotes' => 'Release Notes',
			'settings.downloadingUpdate' => 'Downloading update...',
			'settings.percentComplete' => ({required Object percent}) => '${percent}% complete',
			'settings.updateCheckFailed' => 'Update check failed',
			'settings.downloadModelTooltip' => 'Download Model',
			'settings.ramIndicator.unknown' => 'Device RAM: Unknown',
			'settings.ramIndicator.detected' => ({required Object ram}) => 'Device RAM: ${ram} GB',
			'settings.ramIndicator.safe' => '✅ Safe for your device\'s memory.',
			'settings.ramIndicator.warning' => '⚠️ High risk of out-of-memory errors on this device.',
			'setup.checkingSystem' => 'Checking system state...',
			'setup.startingModel' => 'Starting AI Model...',
			'setup.welcomeTitle' => 'Welcome to\nLocal Assistant',
			'setup.welcomeSubtitle' => 'To get started, please download an AI model. All inference runs locally and privately on your device hardware.',
			'setup.availableModels' => 'AVAILABLE MODELS',
			'setup.downloaded' => 'Downloaded',
			'setup.tapToDownload' => 'Tap to download',
			'setup.checking' => 'Checking...',
			'setup.error' => 'Error',
			'setup.get' => 'Get',
			'setup.startChatting' => 'Start Chatting',
			'download.title' => ({required Object name}) => 'Download ${name}',
			'download.requiresAuth' => 'This model requires HuggingFace access.',
			'download.hfToken' => 'HuggingFace Token',
			'download.hfTokenRequired' => 'HuggingFace Token required.',
			'download.downloading' => ({required Object progress}) => 'Downloading... ${progress}%',
			'download.startDownload' => 'Start Download',
			'download.noInternet' => 'No internet connection detected.',
			'download.mobileDataWarningTitle' => 'Large File Warning',
			'download.mobileDataWarning' => 'You are connected via Mobile Data. This model is a large file (approx 1-2GB) and downloading it may consume significant data or incur additional charges. Proceed anyway?',
			'download.proceed' => 'Proceed',
			'download.cancel' => 'Cancel',
			'download.downloadSuccess' => 'Model downloaded successfully!',
			'download.downloadFailed' => ({required Object error}) => 'Download failed: ${error}',
			'errors.contextOverflow' => '⚠️ Error: The input exceeded strict hardware memory limits. The system attempted to prune memory but the prompt is too large. Please increase \'Total Context Window\' in Settings or start a new chat.',
			'errors.inferenceFailed' => ({required Object error}) => '⚠️ Error: Model inference failed.\nDetails: ${error}',
			'errors.generationFailed' => ({required Object error}) => '⚠️ Error: Failed to start generation.\nDetails: ${error}',
			'common.cancel' => 'Cancel',
			'common.delete' => 'Delete',
			'common.recommended' => 'Recommended',
			_ => null,
		};
	}
}
