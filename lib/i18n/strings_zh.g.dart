///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsZh with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZh({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zh,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsZh _root = this; // ignore: unused_field

	@override 
	TranslationsZh $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZh(meta: meta ?? this.$meta);

	// Translations
	@override String get appTitle => '本地助手';
	@override late final _TranslationsChatZh chat = _TranslationsChatZh._(_root);
	@override late final _TranslationsAttachmentsZh attachments = _TranslationsAttachmentsZh._(_root);
	@override late final _TranslationsSettingsZh settings = _TranslationsSettingsZh._(_root);
	@override late final _TranslationsSetupZh setup = _TranslationsSetupZh._(_root);
	@override late final _TranslationsDownloadZh download = _TranslationsDownloadZh._(_root);
	@override late final _TranslationsErrorsZh errors = _TranslationsErrorsZh._(_root);
	@override late final _TranslationsCommonZh common = _TranslationsCommonZh._(_root);
}

// Path: chat
class _TranslationsChatZh implements TranslationsChatEn {
	_TranslationsChatZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '本地 AI 助手';
	@override String get newChat => '新对话';
	@override String get recentHistory => '最近记录';
	@override String get settingsAndModels => '设置与模型';
	@override String get assistantName => '助手';
	@override String get userName => '我';
	@override String get aiName => '本地 AI';
	@override String get deleteChatTitle => '删除对话';
	@override String deleteChatConfirm({required Object title}) => '您确定要删除“${title}”吗？\n此操作无法撤销。';
	@override String get deleteMessageTitle => '删除消息';
	@override String get deleteMessageConfirm => '您确定要删除整条消息及其附件吗？';
	@override String get chatDeleted => '对话已删除';
	@override String get messageDeleted => '消息已删除';
	@override String get maxAttachments => '每条消息最多允许 2 个附件。';
	@override String get copyMessage => '复制消息';
	@override String get copiedToClipboard => '已复制到剪贴板';
	@override String get deleteMessage => '删除消息';
	@override String get deleteMessageGroup => '删除消息组';
	@override String get composePrompt => '撰写提示';
	@override String get send => '发送';
	@override String get writePromptHint => '在此写下您的详细提示词...';
	@override String get messageHint => '发消息给本地助手...';
	@override String get attachmentSession => '附件会话';
	@override String get generating => '生成中...';
	@override String get stop => '停止';
}

// Path: attachments
class _TranslationsAttachmentsZh implements TranslationsAttachmentsEn {
	_TranslationsAttachmentsZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get photo => '照片';
	@override String get audio => '音频 (.wav)';
	@override String get document => '文档 (.txt, .md, .csv)';
}

// Path: settings
class _TranslationsSettingsZh implements TranslationsSettingsEn {
	_TranslationsSettingsZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '设置';
	@override String get general => '常规';
	@override String get language => '语言';
	@override String get systemLanguage => '系统默认';
	@override String get aiModels => 'AI 模型';
	@override String get inferenceAndMemory => '推理与记忆';
	@override String get behavior => '行为';
	@override String get appUpdate => '应用更新';
	@override String get readyToUse => '准备就绪';
	@override String get notDownloaded => '未下载';
	@override String get checkingStatus => '正在检查状态...';
	@override String get errorCheckingStatus => '检查状态时出错';
	@override String get deleteModelTitle => '删除模型';
	@override String deleteModelConfirm({required Object name}) => '您确定要删除 ${name} 吗？您需要重新下载才能再次使用它。';
	@override String get modelDeleted => '模型删除成功';
	@override String get applyChanges => '应用更改';
	@override String get settingsApplied => '设置应用成功';
	@override String get modelNotDownloaded => '所选模型尚未下载！';
	@override String errorWithDetails({required Object details}) => '错误: ${details}';
	@override String get enableMemoryTitle => '启用跨对话记忆';
	@override String get enableMemorySubtitle => '允许 AI 悄悄引用您其他近期对话中的事实。';
	@override String get totalContextWindow => '总上下文窗口';
	@override String get contextWindowDescription => '用于输入+输出的硬件内存。当达到限制时，智能截断会自动修剪较旧的消息。';
	@override String get tokens => 'Tokens';
	@override String get temperature => '创造力 (Temperature)';
	@override String get temperatureDescription => '控制创造力。越低越专注，越高越随机。';
	@override String get systemInstructions => '系统提示词';
	@override String get systemInstructionsDescription => '自定义指示，用于引导 AI 的整体行为和角色扮演。';
	@override String get systemInstructionsHint => '你是一个有用的 AI 助手。';
	@override String get resetDefaults => '重置为默认值';
	@override String get resetConfirm => '您确定要重置所有推理和行为设置吗？您下载的模型和语言偏好将不受影响。';
	@override String get resetSuccess => '设置已重置为默认值';
	@override String get checkForUpdates => '检查更新';
	@override String get checkingForUpdates => '正在检查更新...';
	@override String get appUpToDate => '应用已是最新版本';
	@override String get latestVersion => '您正在使用最新版本';
	@override String updateAvailable({required Object version}) => '发现新版本: v${version}';
	@override String updateAvailableSnackbar({required Object version}) => '有新的应用更新可用 (v${version})。请查看“设置”以安装。';
	@override String get tapToDownload => '点击下载并安装';
	@override String get releaseNotes => '发行说明';
	@override String get downloadingUpdate => '正在下载更新...';
	@override String percentComplete({required Object percent}) => '已完成 ${percent}%';
	@override String get updateCheckFailed => '更新检查失败';
	@override String get downloadModelTooltip => '下载模型';
	@override late final _TranslationsSettingsRamIndicatorZh ramIndicator = _TranslationsSettingsRamIndicatorZh._(_root);
}

// Path: setup
class _TranslationsSetupZh implements TranslationsSetupEn {
	_TranslationsSetupZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get checkingSystem => '正在检查系统状态...';
	@override String get startingModel => '正在启动 AI 模型...';
	@override String get welcomeTitle => '欢迎使用\n本地助手';
	@override String get welcomeSubtitle => '要开始使用，请下载一个 AI 模型。所有推理都在您的设备硬件上进行本地和私密的运行。';
	@override String get availableModels => '可用模型';
	@override String get downloaded => '已下载';
	@override String get tapToDownload => '点击下载';
	@override String get checking => '正在检查...';
	@override String get error => '错误';
	@override String get get => '获取';
	@override String get startChatting => '开始聊天';
}

// Path: download
class _TranslationsDownloadZh implements TranslationsDownloadEn {
	_TranslationsDownloadZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String title({required Object name}) => '下载 ${name}';
	@override String get requiresAuth => '此模型需要 HuggingFace 授权。';
	@override String get hfToken => 'HuggingFace Token';
	@override String get hfTokenRequired => '需要 HuggingFace Token。';
	@override String downloading({required Object progress}) => '正在下载... ${progress}%';
	@override String get startDownload => '开始下载';
	@override String get noInternet => '未检测到互联网连接。';
	@override String get mobileDataWarningTitle => '大文件警告';
	@override String get mobileDataWarning => '您当前连接的是移动数据网络。此模型是一个大文件（约 1-2GB），下载可能会消耗大量数据流量或产生额外费用。是否继续？';
	@override String get proceed => '继续';
	@override String get cancel => '取消';
	@override String get downloadSuccess => '模型下载成功！';
	@override String downloadFailed({required Object error}) => '下载失败: ${error}';
}

// Path: errors
class _TranslationsErrorsZh implements TranslationsErrorsEn {
	_TranslationsErrorsZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get contextOverflow => '⚠️ 错误：输入超出了严格的硬件内存限制。系统尝试修剪内存，但提示词仍然过大。请在设置中增加“总上下文窗口”或开始新的对话。';
	@override String inferenceFailed({required Object error}) => '⚠️ 错误：模型推理失败。\n详细信息: ${error}';
	@override String generationFailed({required Object error}) => '⚠️ 错误：启动生成失败。\n详细信息: ${error}';
}

// Path: common
class _TranslationsCommonZh implements TranslationsCommonEn {
	_TranslationsCommonZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get cancel => '取消';
	@override String get delete => '删除';
	@override String get recommended => '推荐';
}

// Path: settings.ramIndicator
class _TranslationsSettingsRamIndicatorZh implements TranslationsSettingsRamIndicatorEn {
	_TranslationsSettingsRamIndicatorZh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get unknown => '设备内存: 未知';
	@override String detected({required Object ram}) => '设备内存: ${ram} GB';
	@override String get safe => '✅ 对您设备的内存是安全的。';
	@override String get warning => '⚠️ 在此设备上有很高的内存不足错误风险。';
}

/// The flat map containing all translations for locale <zh>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZh {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appTitle' => '本地助手',
			'chat.title' => '本地 AI 助手',
			'chat.newChat' => '新对话',
			'chat.recentHistory' => '最近记录',
			'chat.settingsAndModels' => '设置与模型',
			'chat.assistantName' => '助手',
			'chat.userName' => '我',
			'chat.aiName' => '本地 AI',
			'chat.deleteChatTitle' => '删除对话',
			'chat.deleteChatConfirm' => ({required Object title}) => '您确定要删除“${title}”吗？\n此操作无法撤销。',
			'chat.deleteMessageTitle' => '删除消息',
			'chat.deleteMessageConfirm' => '您确定要删除整条消息及其附件吗？',
			'chat.chatDeleted' => '对话已删除',
			'chat.messageDeleted' => '消息已删除',
			'chat.maxAttachments' => '每条消息最多允许 2 个附件。',
			'chat.copyMessage' => '复制消息',
			'chat.copiedToClipboard' => '已复制到剪贴板',
			'chat.deleteMessage' => '删除消息',
			'chat.deleteMessageGroup' => '删除消息组',
			'chat.composePrompt' => '撰写提示',
			'chat.send' => '发送',
			'chat.writePromptHint' => '在此写下您的详细提示词...',
			'chat.messageHint' => '发消息给本地助手...',
			'chat.attachmentSession' => '附件会话',
			'chat.generating' => '生成中...',
			'chat.stop' => '停止',
			'attachments.photo' => '照片',
			'attachments.audio' => '音频 (.wav)',
			'attachments.document' => '文档 (.txt, .md, .csv)',
			'settings.title' => '设置',
			'settings.general' => '常规',
			'settings.language' => '语言',
			'settings.systemLanguage' => '系统默认',
			'settings.aiModels' => 'AI 模型',
			'settings.inferenceAndMemory' => '推理与记忆',
			'settings.behavior' => '行为',
			'settings.appUpdate' => '应用更新',
			'settings.readyToUse' => '准备就绪',
			'settings.notDownloaded' => '未下载',
			'settings.checkingStatus' => '正在检查状态...',
			'settings.errorCheckingStatus' => '检查状态时出错',
			'settings.deleteModelTitle' => '删除模型',
			'settings.deleteModelConfirm' => ({required Object name}) => '您确定要删除 ${name} 吗？您需要重新下载才能再次使用它。',
			'settings.modelDeleted' => '模型删除成功',
			'settings.applyChanges' => '应用更改',
			'settings.settingsApplied' => '设置应用成功',
			'settings.modelNotDownloaded' => '所选模型尚未下载！',
			'settings.errorWithDetails' => ({required Object details}) => '错误: ${details}',
			'settings.enableMemoryTitle' => '启用跨对话记忆',
			'settings.enableMemorySubtitle' => '允许 AI 悄悄引用您其他近期对话中的事实。',
			'settings.totalContextWindow' => '总上下文窗口',
			'settings.contextWindowDescription' => '用于输入+输出的硬件内存。当达到限制时，智能截断会自动修剪较旧的消息。',
			'settings.tokens' => 'Tokens',
			'settings.temperature' => '创造力 (Temperature)',
			'settings.temperatureDescription' => '控制创造力。越低越专注，越高越随机。',
			'settings.systemInstructions' => '系统提示词',
			'settings.systemInstructionsDescription' => '自定义指示，用于引导 AI 的整体行为和角色扮演。',
			'settings.systemInstructionsHint' => '你是一个有用的 AI 助手。',
			'settings.resetDefaults' => '重置为默认值',
			'settings.resetConfirm' => '您确定要重置所有推理和行为设置吗？您下载的模型和语言偏好将不受影响。',
			'settings.resetSuccess' => '设置已重置为默认值',
			'settings.checkForUpdates' => '检查更新',
			'settings.checkingForUpdates' => '正在检查更新...',
			'settings.appUpToDate' => '应用已是最新版本',
			'settings.latestVersion' => '您正在使用最新版本',
			'settings.updateAvailable' => ({required Object version}) => '发现新版本: v${version}',
			'settings.updateAvailableSnackbar' => ({required Object version}) => '有新的应用更新可用 (v${version})。请查看“设置”以安装。',
			'settings.tapToDownload' => '点击下载并安装',
			'settings.releaseNotes' => '发行说明',
			'settings.downloadingUpdate' => '正在下载更新...',
			'settings.percentComplete' => ({required Object percent}) => '已完成 ${percent}%',
			'settings.updateCheckFailed' => '更新检查失败',
			'settings.downloadModelTooltip' => '下载模型',
			'settings.ramIndicator.unknown' => '设备内存: 未知',
			'settings.ramIndicator.detected' => ({required Object ram}) => '设备内存: ${ram} GB',
			'settings.ramIndicator.safe' => '✅ 对您设备的内存是安全的。',
			'settings.ramIndicator.warning' => '⚠️ 在此设备上有很高的内存不足错误风险。',
			'setup.checkingSystem' => '正在检查系统状态...',
			'setup.startingModel' => '正在启动 AI 模型...',
			'setup.welcomeTitle' => '欢迎使用\n本地助手',
			'setup.welcomeSubtitle' => '要开始使用，请下载一个 AI 模型。所有推理都在您的设备硬件上进行本地和私密的运行。',
			'setup.availableModels' => '可用模型',
			'setup.downloaded' => '已下载',
			'setup.tapToDownload' => '点击下载',
			'setup.checking' => '正在检查...',
			'setup.error' => '错误',
			'setup.get' => '获取',
			'setup.startChatting' => '开始聊天',
			'download.title' => ({required Object name}) => '下载 ${name}',
			'download.requiresAuth' => '此模型需要 HuggingFace 授权。',
			'download.hfToken' => 'HuggingFace Token',
			'download.hfTokenRequired' => '需要 HuggingFace Token。',
			'download.downloading' => ({required Object progress}) => '正在下载... ${progress}%',
			'download.startDownload' => '开始下载',
			'download.noInternet' => '未检测到互联网连接。',
			'download.mobileDataWarningTitle' => '大文件警告',
			'download.mobileDataWarning' => '您当前连接的是移动数据网络。此模型是一个大文件（约 1-2GB），下载可能会消耗大量数据流量或产生额外费用。是否继续？',
			'download.proceed' => '继续',
			'download.cancel' => '取消',
			'download.downloadSuccess' => '模型下载成功！',
			'download.downloadFailed' => ({required Object error}) => '下载失败: ${error}',
			'errors.contextOverflow' => '⚠️ 错误：输入超出了严格的硬件内存限制。系统尝试修剪内存，但提示词仍然过大。请在设置中增加“总上下文窗口”或开始新的对话。',
			'errors.inferenceFailed' => ({required Object error}) => '⚠️ 错误：模型推理失败。\n详细信息: ${error}',
			'errors.generationFailed' => ({required Object error}) => '⚠️ 错误：启动生成失败。\n详细信息: ${error}',
			'common.cancel' => '取消',
			'common.delete' => '删除',
			'common.recommended' => '推荐',
			_ => null,
		};
	}
}
