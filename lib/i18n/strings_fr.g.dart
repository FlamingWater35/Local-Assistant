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
class TranslationsFr with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsFr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.fr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fr>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsFr _root = this; // ignore: unused_field

	@override 
	TranslationsFr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsFr(meta: meta ?? this.$meta);

	// Translations
	@override String get appTitle => 'Assistant Local';
	@override late final _TranslationsChatFr chat = _TranslationsChatFr._(_root);
	@override late final _TranslationsAttachmentsFr attachments = _TranslationsAttachmentsFr._(_root);
	@override late final _TranslationsSettingsFr settings = _TranslationsSettingsFr._(_root);
	@override late final _TranslationsSetupFr setup = _TranslationsSetupFr._(_root);
	@override late final _TranslationsDownloadFr download = _TranslationsDownloadFr._(_root);
	@override late final _TranslationsErrorsFr errors = _TranslationsErrorsFr._(_root);
	@override late final _TranslationsCommonFr common = _TranslationsCommonFr._(_root);
}

// Path: chat
class _TranslationsChatFr implements TranslationsChatEn {
	_TranslationsChatFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Assistant IA Local';
	@override String get newChat => 'Nouveau Chat';
	@override String get recentHistory => 'Historique récent';
	@override String get settingsAndModels => 'Paramètres & Modèles';
	@override String get assistantName => 'Assistant';
	@override String get userName => 'Moi';
	@override String get aiName => 'IA Locale';
	@override String get deleteChatTitle => 'Supprimer le chat';
	@override String deleteChatConfirm({required Object title}) => 'Êtes-vous sûr de vouloir supprimer "${title}" ?\nCette action est irréversible.';
	@override String get deleteMessageTitle => 'Supprimer le message';
	@override String get deleteMessageConfirm => 'Êtes-vous sûr de vouloir supprimer l\'intégralité de ce message et ses pièces jointes ?';
	@override String get chatDeleted => 'Chat supprimé';
	@override String get messageDeleted => 'Message supprimé';
	@override String get maxAttachments => 'Maximum de 2 pièces jointes autorisées par message.';
	@override String get copyMessage => 'Copier le message';
	@override String get copiedToClipboard => 'Copié dans le presse-papiers';
	@override String get deleteMessage => 'Supprimer le message';
	@override String get deleteMessageGroup => 'Supprimer le groupe de messages';
	@override String get composePrompt => 'Rédiger un message';
	@override String get send => 'Envoyer';
	@override String get writePromptHint => 'Écrivez votre message détaillé ici...';
	@override String get messageHint => 'Message pour l\'Assistant Local...';
	@override String get attachmentSession => 'Session de pièces jointes';
}

// Path: attachments
class _TranslationsAttachmentsFr implements TranslationsAttachmentsEn {
	_TranslationsAttachmentsFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get photo => 'Photo';
	@override String get audio => 'Audio (.wav)';
	@override String get document => 'Document (.txt, .md, .csv)';
}

// Path: settings
class _TranslationsSettingsFr implements TranslationsSettingsEn {
	_TranslationsSettingsFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Paramètres';
	@override String get general => 'Général';
	@override String get language => 'Langue';
	@override String get systemLanguage => 'Par défaut du système';
	@override String get aiModels => 'Modèles d\'IA';
	@override String get inferenceAndMemory => 'Inférence & Mémoire';
	@override String get behavior => 'Comportement';
	@override String get appUpdate => 'Mise à jour de l\'app';
	@override String get readyToUse => 'Prêt à utiliser';
	@override String get notDownloaded => 'Non téléchargé';
	@override String get checkingStatus => 'Vérification de l\'état...';
	@override String get errorCheckingStatus => 'Erreur lors de la vérification';
	@override String get deleteModelTitle => 'Supprimer le modèle';
	@override String deleteModelConfirm({required Object name}) => 'Êtes-vous sûr de vouloir supprimer ${name} ? Vous devrez le télécharger à nouveau pour l\'utiliser.';
	@override String get modelDeleted => 'Modèle supprimé avec succès';
	@override String get applyChanges => 'Appliquer les modifications';
	@override String get settingsApplied => 'Paramètres appliqués avec succès';
	@override String get modelNotDownloaded => 'Le modèle sélectionné n\'est pas téléchargé !';
	@override String errorWithDetails({required Object details}) => 'Erreur: ${details}';
	@override String get enableMemoryTitle => 'Activer la mémoire sur tous les chats';
	@override String get enableMemorySubtitle => 'Permet à l\'IA de se référer silencieusement aux faits de vos autres conversations récentes.';
	@override String get totalContextWindow => 'Fenêtre de contexte totale';
	@override String get contextWindowDescription => 'Mémoire matérielle pour Entrée + Sortie. La troncature intelligente supprimera automatiquement les anciens messages lorsque la limite sera atteinte.';
	@override String get tokens => 'Jetons';
	@override String get temperature => 'Température';
	@override String get temperatureDescription => 'Contrôle la créativité. Plus c\'est bas, plus c\'est concentré, plus c\'est haut, plus c\'est aléatoire.';
	@override String get checkForUpdates => 'Vérifier les mises à jour';
	@override String get checkingForUpdates => 'Vérification des mises à jour...';
	@override String get appUpToDate => 'L\'application est à jour';
	@override String get latestVersion => 'Vous utilisez la dernière version';
	@override String updateAvailable({required Object version}) => 'Mise à jour disponible: v${version}';
	@override String updateAvailableSnackbar({required Object version}) => 'Une nouvelle mise à jour (v${version}) est disponible. Consultez les paramètres pour l\'installer.';
	@override String get tapToDownload => 'Appuyez pour télécharger et installer';
	@override String get releaseNotes => 'Notes de version';
	@override String get downloadingUpdate => 'Téléchargement de la mise à jour...';
	@override String percentComplete({required Object percent}) => '${percent}% terminé';
	@override String get updateCheckFailed => 'Échec de la vérification';
	@override String get downloadModelTooltip => 'Télécharger le modèle';
}

// Path: setup
class _TranslationsSetupFr implements TranslationsSetupEn {
	_TranslationsSetupFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get checkingSystem => 'Vérification de l\'état du système...';
	@override String get startingModel => 'Démarrage du modèle IA...';
	@override String get welcomeTitle => 'Bienvenue sur\nAssistant Local';
	@override String get welcomeSubtitle => 'Pour commencer, veuillez télécharger un modèle d\'IA. Toutes les inférences s\'exécutent localement et de manière privée sur votre matériel.';
	@override String get availableModels => 'MODÈLES DISPONIBLES';
	@override String get downloaded => 'Téléchargé';
	@override String get tapToDownload => 'Appuyez pour télécharger';
	@override String get checking => 'Vérification...';
	@override String get error => 'Erreur';
	@override String get get => 'Obtenir';
	@override String get startChatting => 'Commencer à discuter';
}

// Path: download
class _TranslationsDownloadFr implements TranslationsDownloadEn {
	_TranslationsDownloadFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String title({required Object name}) => 'Télécharger ${name}';
	@override String get requiresAuth => 'Ce modèle nécessite un accès HuggingFace.';
	@override String get hfToken => 'Jeton HuggingFace';
	@override String get hfTokenRequired => 'Jeton HuggingFace requis.';
	@override String downloading({required Object progress}) => 'Téléchargement... ${progress}%';
	@override String get startDownload => 'Lancer le téléchargement';
	@override String get noInternet => 'Aucune connexion Internet détectée.';
	@override String get mobileDataWarningTitle => 'Avertissement fichier volumineux';
	@override String get mobileDataWarning => 'Vous êtes connecté via les données mobiles. Ce modèle est un fichier volumineux (environ 1-2 Go) et son téléchargement peut consommer des données importantes. Continuer quand même ?';
	@override String get proceed => 'Continuer';
	@override String get cancel => 'Annuler';
	@override String get downloadSuccess => 'Modèle téléchargé avec succès !';
	@override String downloadFailed({required Object error}) => 'Échec du téléchargement: ${error}';
}

// Path: errors
class _TranslationsErrorsFr implements TranslationsErrorsEn {
	_TranslationsErrorsFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get contextOverflow => '⚠️ Erreur: L\'entrée a dépassé les limites strictes de la mémoire matérielle. Le système a tenté d\'élaguer la mémoire mais le message est trop grand. Veuillez augmenter la \'Fenêtre de contexte totale\' dans les paramètres ou démarrer un nouveau chat.';
	@override String inferenceFailed({required Object error}) => '⚠️ Erreur: L\'inférence du modèle a échoué.\nDétails: ${error}';
	@override String generationFailed({required Object error}) => '⚠️ Erreur: Échec du démarrage de la génération.\nDétails: ${error}';
}

// Path: common
class _TranslationsCommonFr implements TranslationsCommonEn {
	_TranslationsCommonFr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Annuler';
	@override String get delete => 'Supprimer';
}

/// The flat map containing all translations for locale <fr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsFr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appTitle' => 'Assistant Local',
			'chat.title' => 'Assistant IA Local',
			'chat.newChat' => 'Nouveau Chat',
			'chat.recentHistory' => 'Historique récent',
			'chat.settingsAndModels' => 'Paramètres & Modèles',
			'chat.assistantName' => 'Assistant',
			'chat.userName' => 'Moi',
			'chat.aiName' => 'IA Locale',
			'chat.deleteChatTitle' => 'Supprimer le chat',
			'chat.deleteChatConfirm' => ({required Object title}) => 'Êtes-vous sûr de vouloir supprimer "${title}" ?\nCette action est irréversible.',
			'chat.deleteMessageTitle' => 'Supprimer le message',
			'chat.deleteMessageConfirm' => 'Êtes-vous sûr de vouloir supprimer l\'intégralité de ce message et ses pièces jointes ?',
			'chat.chatDeleted' => 'Chat supprimé',
			'chat.messageDeleted' => 'Message supprimé',
			'chat.maxAttachments' => 'Maximum de 2 pièces jointes autorisées par message.',
			'chat.copyMessage' => 'Copier le message',
			'chat.copiedToClipboard' => 'Copié dans le presse-papiers',
			'chat.deleteMessage' => 'Supprimer le message',
			'chat.deleteMessageGroup' => 'Supprimer le groupe de messages',
			'chat.composePrompt' => 'Rédiger un message',
			'chat.send' => 'Envoyer',
			'chat.writePromptHint' => 'Écrivez votre message détaillé ici...',
			'chat.messageHint' => 'Message pour l\'Assistant Local...',
			'chat.attachmentSession' => 'Session de pièces jointes',
			'attachments.photo' => 'Photo',
			'attachments.audio' => 'Audio (.wav)',
			'attachments.document' => 'Document (.txt, .md, .csv)',
			'settings.title' => 'Paramètres',
			'settings.general' => 'Général',
			'settings.language' => 'Langue',
			'settings.systemLanguage' => 'Par défaut du système',
			'settings.aiModels' => 'Modèles d\'IA',
			'settings.inferenceAndMemory' => 'Inférence & Mémoire',
			'settings.behavior' => 'Comportement',
			'settings.appUpdate' => 'Mise à jour de l\'app',
			'settings.readyToUse' => 'Prêt à utiliser',
			'settings.notDownloaded' => 'Non téléchargé',
			'settings.checkingStatus' => 'Vérification de l\'état...',
			'settings.errorCheckingStatus' => 'Erreur lors de la vérification',
			'settings.deleteModelTitle' => 'Supprimer le modèle',
			'settings.deleteModelConfirm' => ({required Object name}) => 'Êtes-vous sûr de vouloir supprimer ${name} ? Vous devrez le télécharger à nouveau pour l\'utiliser.',
			'settings.modelDeleted' => 'Modèle supprimé avec succès',
			'settings.applyChanges' => 'Appliquer les modifications',
			'settings.settingsApplied' => 'Paramètres appliqués avec succès',
			'settings.modelNotDownloaded' => 'Le modèle sélectionné n\'est pas téléchargé !',
			'settings.errorWithDetails' => ({required Object details}) => 'Erreur: ${details}',
			'settings.enableMemoryTitle' => 'Activer la mémoire sur tous les chats',
			'settings.enableMemorySubtitle' => 'Permet à l\'IA de se référer silencieusement aux faits de vos autres conversations récentes.',
			'settings.totalContextWindow' => 'Fenêtre de contexte totale',
			'settings.contextWindowDescription' => 'Mémoire matérielle pour Entrée + Sortie. La troncature intelligente supprimera automatiquement les anciens messages lorsque la limite sera atteinte.',
			'settings.tokens' => 'Jetons',
			'settings.temperature' => 'Température',
			'settings.temperatureDescription' => 'Contrôle la créativité. Plus c\'est bas, plus c\'est concentré, plus c\'est haut, plus c\'est aléatoire.',
			'settings.checkForUpdates' => 'Vérifier les mises à jour',
			'settings.checkingForUpdates' => 'Vérification des mises à jour...',
			'settings.appUpToDate' => 'L\'application est à jour',
			'settings.latestVersion' => 'Vous utilisez la dernière version',
			'settings.updateAvailable' => ({required Object version}) => 'Mise à jour disponible: v${version}',
			'settings.updateAvailableSnackbar' => ({required Object version}) => 'Une nouvelle mise à jour (v${version}) est disponible. Consultez les paramètres pour l\'installer.',
			'settings.tapToDownload' => 'Appuyez pour télécharger et installer',
			'settings.releaseNotes' => 'Notes de version',
			'settings.downloadingUpdate' => 'Téléchargement de la mise à jour...',
			'settings.percentComplete' => ({required Object percent}) => '${percent}% terminé',
			'settings.updateCheckFailed' => 'Échec de la vérification',
			'settings.downloadModelTooltip' => 'Télécharger le modèle',
			'setup.checkingSystem' => 'Vérification de l\'état du système...',
			'setup.startingModel' => 'Démarrage du modèle IA...',
			'setup.welcomeTitle' => 'Bienvenue sur\nAssistant Local',
			'setup.welcomeSubtitle' => 'Pour commencer, veuillez télécharger un modèle d\'IA. Toutes les inférences s\'exécutent localement et de manière privée sur votre matériel.',
			'setup.availableModels' => 'MODÈLES DISPONIBLES',
			'setup.downloaded' => 'Téléchargé',
			'setup.tapToDownload' => 'Appuyez pour télécharger',
			'setup.checking' => 'Vérification...',
			'setup.error' => 'Erreur',
			'setup.get' => 'Obtenir',
			'setup.startChatting' => 'Commencer à discuter',
			'download.title' => ({required Object name}) => 'Télécharger ${name}',
			'download.requiresAuth' => 'Ce modèle nécessite un accès HuggingFace.',
			'download.hfToken' => 'Jeton HuggingFace',
			'download.hfTokenRequired' => 'Jeton HuggingFace requis.',
			'download.downloading' => ({required Object progress}) => 'Téléchargement... ${progress}%',
			'download.startDownload' => 'Lancer le téléchargement',
			'download.noInternet' => 'Aucune connexion Internet détectée.',
			'download.mobileDataWarningTitle' => 'Avertissement fichier volumineux',
			'download.mobileDataWarning' => 'Vous êtes connecté via les données mobiles. Ce modèle est un fichier volumineux (environ 1-2 Go) et son téléchargement peut consommer des données importantes. Continuer quand même ?',
			'download.proceed' => 'Continuer',
			'download.cancel' => 'Annuler',
			'download.downloadSuccess' => 'Modèle téléchargé avec succès !',
			'download.downloadFailed' => ({required Object error}) => 'Échec du téléchargement: ${error}',
			'errors.contextOverflow' => '⚠️ Erreur: L\'entrée a dépassé les limites strictes de la mémoire matérielle. Le système a tenté d\'élaguer la mémoire mais le message est trop grand. Veuillez augmenter la \'Fenêtre de contexte totale\' dans les paramètres ou démarrer un nouveau chat.',
			'errors.inferenceFailed' => ({required Object error}) => '⚠️ Erreur: L\'inférence du modèle a échoué.\nDétails: ${error}',
			'errors.generationFailed' => ({required Object error}) => '⚠️ Erreur: Échec du démarrage de la génération.\nDétails: ${error}',
			'common.cancel' => 'Annuler',
			'common.delete' => 'Supprimer',
			_ => null,
		};
	}
}
