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
class TranslationsDe with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsDe({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <de>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsDe _root = this; // ignore: unused_field

	@override 
	TranslationsDe $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsDe(meta: meta ?? this.$meta);

	// Translations
	@override String get appTitle => 'Lokaler Assistent';
	@override late final _TranslationsChatDe chat = _TranslationsChatDe._(_root);
	@override late final _TranslationsAttachmentsDe attachments = _TranslationsAttachmentsDe._(_root);
	@override late final _TranslationsSettingsDe settings = _TranslationsSettingsDe._(_root);
	@override late final _TranslationsSetupDe setup = _TranslationsSetupDe._(_root);
	@override late final _TranslationsDownloadDe download = _TranslationsDownloadDe._(_root);
	@override late final _TranslationsErrorsDe errors = _TranslationsErrorsDe._(_root);
	@override late final _TranslationsCommonDe common = _TranslationsCommonDe._(_root);
}

// Path: chat
class _TranslationsChatDe implements TranslationsChatEn {
	_TranslationsChatDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Lokaler KI-Assistent';
	@override String get newChat => 'Neuer Chat';
	@override String get recentHistory => 'Letzter Verlauf';
	@override String get settingsAndModels => 'Einstellungen & Modelle';
	@override String get assistantName => 'Assistent';
	@override String get userName => 'Ich';
	@override String get aiName => 'Lokale KI';
	@override String get deleteChatTitle => 'Chat löschen';
	@override String deleteChatConfirm({required Object title}) => 'Möchten Sie "${title}" wirklich löschen?\nDies kann nicht rückgängig gemacht werden.';
	@override String get deleteMessageTitle => 'Nachricht löschen';
	@override String get deleteMessageConfirm => 'Möchten Sie diese gesamte Nachricht und ihre Anhänge wirklich löschen?';
	@override String get chatDeleted => 'Chat gelöscht';
	@override String get messageDeleted => 'Nachricht gelöscht';
	@override String get maxAttachments => 'Maximal 2 Anhänge pro Nachricht erlaubt.';
	@override String get copyMessage => 'Nachricht kopieren';
	@override String get copiedToClipboard => 'In die Zwischenablage kopiert';
	@override String get deleteMessage => 'Nachricht löschen';
	@override String get deleteMessageGroup => 'Nachrichtengruppe löschen';
	@override String get composePrompt => 'Eingabeaufforderung verfassen';
	@override String get send => 'Senden';
	@override String get writePromptHint => 'Schreiben Sie hier Ihre ausführliche Eingabeaufforderung...';
	@override String get messageHint => 'Nachricht an Lokalen Assistenten...';
	@override String get attachmentSession => 'Anhangs-Sitzung';
}

// Path: attachments
class _TranslationsAttachmentsDe implements TranslationsAttachmentsEn {
	_TranslationsAttachmentsDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get photo => 'Foto';
	@override String get audio => 'Audio (.wav)';
	@override String get document => 'Dokument (.txt, .md, .csv)';
}

// Path: settings
class _TranslationsSettingsDe implements TranslationsSettingsEn {
	_TranslationsSettingsDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Einstellungen';
	@override String get general => 'Allgemein';
	@override String get language => 'Sprache';
	@override String get systemLanguage => 'Systemstandard';
	@override String get aiModels => 'KI-Modelle';
	@override String get inferenceAndMemory => 'Inferenz & Gedächtnis';
	@override String get behavior => 'Verhalten';
	@override String get appUpdate => 'App-Update';
	@override String get readyToUse => 'Einsatzbereit';
	@override String get notDownloaded => 'Nicht heruntergeladen';
	@override String get checkingStatus => 'Status wird überprüft...';
	@override String get errorCheckingStatus => 'Fehler beim Überprüfen';
	@override String get deleteModelTitle => 'Modell löschen';
	@override String deleteModelConfirm({required Object name}) => 'Möchten Sie ${name} wirklich löschen? Sie müssen es erneut herunterladen, um es zu verwenden.';
	@override String get modelDeleted => 'Modell erfolgreich gelöscht';
	@override String get applyChanges => 'Änderungen übernehmen';
	@override String get settingsApplied => 'Einstellungen erfolgreich angewendet';
	@override String get modelNotDownloaded => 'Das ausgewählte Modell ist nicht heruntergeladen!';
	@override String errorWithDetails({required Object details}) => 'Fehler: ${details}';
	@override String get enableMemoryTitle => 'Gedächtnis für Chats aktivieren';
	@override String get enableMemorySubtitle => 'Erlaubt der KI, sich im Hintergrund auf Fakten aus Ihren anderen aktuellen Unterhaltungen zu beziehen.';
	@override String get totalContextWindow => 'Gesamtes Kontextfenster';
	@override String get contextWindowDescription => 'Hardware-Speicher für Ein- + Ausgabe. Die intelligente Kürzung entfernt automatisch ältere Nachrichten, wenn das Limit erreicht ist.';
	@override String get tokens => 'Token';
	@override String get temperature => 'Temperatur';
	@override String get temperatureDescription => 'Steuert die Kreativität. Niedriger ist fokussierter, höher ist zufälliger.';
	@override String get checkForUpdates => 'Auf Updates prüfen';
	@override String get checkingForUpdates => 'Suche nach Updates...';
	@override String get appUpToDate => 'App ist auf dem neuesten Stand';
	@override String get latestVersion => 'Sie verwenden die neueste Version';
	@override String updateAvailable({required Object version}) => 'Update verfügbar: v${version}';
	@override String updateAvailableSnackbar({required Object version}) => 'Ein neues App-Update (v${version}) ist verfügbar. Gehen Sie in die Einstellungen zur Installation.';
	@override String get tapToDownload => 'Tippen zum Herunterladen und Installieren';
	@override String get releaseNotes => 'Versionshinweise';
	@override String get downloadingUpdate => 'Update wird heruntergeladen...';
	@override String percentComplete({required Object percent}) => '${percent}% abgeschlossen';
	@override String get updateCheckFailed => 'Fehler bei der Update-Suche';
	@override String get downloadModelTooltip => 'Modell herunterladen';
}

// Path: setup
class _TranslationsSetupDe implements TranslationsSetupEn {
	_TranslationsSetupDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get checkingSystem => 'Systemstatus wird überprüft...';
	@override String get startingModel => 'KI-Modell wird gestartet...';
	@override String get welcomeTitle => 'Willkommen beim\nLokalen Assistenten';
	@override String get welcomeSubtitle => 'Um loszulegen, laden Sie bitte ein KI-Modell herunter. Alle Inferenzen laufen lokal und privat auf der Hardware Ihres Geräts.';
	@override String get availableModels => 'VERFÜGBARE MODELLE';
	@override String get downloaded => 'Heruntergeladen';
	@override String get tapToDownload => 'Tippen zum Herunterladen';
	@override String get checking => 'Wird überprüft...';
	@override String get error => 'Fehler';
	@override String get get => 'Holen';
	@override String get startChatting => 'Chat starten';
}

// Path: download
class _TranslationsDownloadDe implements TranslationsDownloadEn {
	_TranslationsDownloadDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String title({required Object name}) => 'Download ${name}';
	@override String get requiresAuth => 'Dieses Modell erfordert einen HuggingFace-Zugang.';
	@override String get hfToken => 'HuggingFace Token';
	@override String get hfTokenRequired => 'HuggingFace Token erforderlich.';
	@override String downloading({required Object progress}) => 'Wird heruntergeladen... ${progress}%';
	@override String get startDownload => 'Download starten';
	@override String get noInternet => 'Keine Internetverbindung erkannt.';
	@override String get mobileDataWarningTitle => 'Warnung vor großen Dateien';
	@override String get mobileDataWarning => 'Sie sind über mobile Daten verbunden. Dieses Modell ist eine große Datei (ca. 1-2 GB). Das Herunterladen kann viele Daten verbrauchen oder zusätzliche Kosten verursachen. Trotzdem fortfahren?';
	@override String get proceed => 'Fortfahren';
	@override String get cancel => 'Abbrechen';
	@override String get downloadSuccess => 'Modell erfolgreich heruntergeladen!';
	@override String downloadFailed({required Object error}) => 'Download fehlgeschlagen: ${error}';
}

// Path: errors
class _TranslationsErrorsDe implements TranslationsErrorsEn {
	_TranslationsErrorsDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get contextOverflow => '⚠️ Fehler: Die Eingabe überschreitet die strengen Hardware-Speichergrenzen. Das System hat versucht, den Speicher zu verkleinern, aber die Anfrage ist zu groß. Bitte erhöhen Sie das \'Gesamte Kontextfenster\' in den Einstellungen oder starten Sie einen neuen Chat.';
	@override String inferenceFailed({required Object error}) => '⚠️ Fehler: Modellinferenz fehlgeschlagen.\nDetails: ${error}';
	@override String generationFailed({required Object error}) => '⚠️ Fehler: Generierung konnte nicht gestartet werden.\nDetails: ${error}';
}

// Path: common
class _TranslationsCommonDe implements TranslationsCommonEn {
	_TranslationsCommonDe._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Abbrechen';
	@override String get delete => 'Löschen';
}

/// The flat map containing all translations for locale <de>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsDe {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appTitle' => 'Lokaler Assistent',
			'chat.title' => 'Lokaler KI-Assistent',
			'chat.newChat' => 'Neuer Chat',
			'chat.recentHistory' => 'Letzter Verlauf',
			'chat.settingsAndModels' => 'Einstellungen & Modelle',
			'chat.assistantName' => 'Assistent',
			'chat.userName' => 'Ich',
			'chat.aiName' => 'Lokale KI',
			'chat.deleteChatTitle' => 'Chat löschen',
			'chat.deleteChatConfirm' => ({required Object title}) => 'Möchten Sie "${title}" wirklich löschen?\nDies kann nicht rückgängig gemacht werden.',
			'chat.deleteMessageTitle' => 'Nachricht löschen',
			'chat.deleteMessageConfirm' => 'Möchten Sie diese gesamte Nachricht und ihre Anhänge wirklich löschen?',
			'chat.chatDeleted' => 'Chat gelöscht',
			'chat.messageDeleted' => 'Nachricht gelöscht',
			'chat.maxAttachments' => 'Maximal 2 Anhänge pro Nachricht erlaubt.',
			'chat.copyMessage' => 'Nachricht kopieren',
			'chat.copiedToClipboard' => 'In die Zwischenablage kopiert',
			'chat.deleteMessage' => 'Nachricht löschen',
			'chat.deleteMessageGroup' => 'Nachrichtengruppe löschen',
			'chat.composePrompt' => 'Eingabeaufforderung verfassen',
			'chat.send' => 'Senden',
			'chat.writePromptHint' => 'Schreiben Sie hier Ihre ausführliche Eingabeaufforderung...',
			'chat.messageHint' => 'Nachricht an Lokalen Assistenten...',
			'chat.attachmentSession' => 'Anhangs-Sitzung',
			'attachments.photo' => 'Foto',
			'attachments.audio' => 'Audio (.wav)',
			'attachments.document' => 'Dokument (.txt, .md, .csv)',
			'settings.title' => 'Einstellungen',
			'settings.general' => 'Allgemein',
			'settings.language' => 'Sprache',
			'settings.systemLanguage' => 'Systemstandard',
			'settings.aiModels' => 'KI-Modelle',
			'settings.inferenceAndMemory' => 'Inferenz & Gedächtnis',
			'settings.behavior' => 'Verhalten',
			'settings.appUpdate' => 'App-Update',
			'settings.readyToUse' => 'Einsatzbereit',
			'settings.notDownloaded' => 'Nicht heruntergeladen',
			'settings.checkingStatus' => 'Status wird überprüft...',
			'settings.errorCheckingStatus' => 'Fehler beim Überprüfen',
			'settings.deleteModelTitle' => 'Modell löschen',
			'settings.deleteModelConfirm' => ({required Object name}) => 'Möchten Sie ${name} wirklich löschen? Sie müssen es erneut herunterladen, um es zu verwenden.',
			'settings.modelDeleted' => 'Modell erfolgreich gelöscht',
			'settings.applyChanges' => 'Änderungen übernehmen',
			'settings.settingsApplied' => 'Einstellungen erfolgreich angewendet',
			'settings.modelNotDownloaded' => 'Das ausgewählte Modell ist nicht heruntergeladen!',
			'settings.errorWithDetails' => ({required Object details}) => 'Fehler: ${details}',
			'settings.enableMemoryTitle' => 'Gedächtnis für Chats aktivieren',
			'settings.enableMemorySubtitle' => 'Erlaubt der KI, sich im Hintergrund auf Fakten aus Ihren anderen aktuellen Unterhaltungen zu beziehen.',
			'settings.totalContextWindow' => 'Gesamtes Kontextfenster',
			'settings.contextWindowDescription' => 'Hardware-Speicher für Ein- + Ausgabe. Die intelligente Kürzung entfernt automatisch ältere Nachrichten, wenn das Limit erreicht ist.',
			'settings.tokens' => 'Token',
			'settings.temperature' => 'Temperatur',
			'settings.temperatureDescription' => 'Steuert die Kreativität. Niedriger ist fokussierter, höher ist zufälliger.',
			'settings.checkForUpdates' => 'Auf Updates prüfen',
			'settings.checkingForUpdates' => 'Suche nach Updates...',
			'settings.appUpToDate' => 'App ist auf dem neuesten Stand',
			'settings.latestVersion' => 'Sie verwenden die neueste Version',
			'settings.updateAvailable' => ({required Object version}) => 'Update verfügbar: v${version}',
			'settings.updateAvailableSnackbar' => ({required Object version}) => 'Ein neues App-Update (v${version}) ist verfügbar. Gehen Sie in die Einstellungen zur Installation.',
			'settings.tapToDownload' => 'Tippen zum Herunterladen und Installieren',
			'settings.releaseNotes' => 'Versionshinweise',
			'settings.downloadingUpdate' => 'Update wird heruntergeladen...',
			'settings.percentComplete' => ({required Object percent}) => '${percent}% abgeschlossen',
			'settings.updateCheckFailed' => 'Fehler bei der Update-Suche',
			'settings.downloadModelTooltip' => 'Modell herunterladen',
			'setup.checkingSystem' => 'Systemstatus wird überprüft...',
			'setup.startingModel' => 'KI-Modell wird gestartet...',
			'setup.welcomeTitle' => 'Willkommen beim\nLokalen Assistenten',
			'setup.welcomeSubtitle' => 'Um loszulegen, laden Sie bitte ein KI-Modell herunter. Alle Inferenzen laufen lokal und privat auf der Hardware Ihres Geräts.',
			'setup.availableModels' => 'VERFÜGBARE MODELLE',
			'setup.downloaded' => 'Heruntergeladen',
			'setup.tapToDownload' => 'Tippen zum Herunterladen',
			'setup.checking' => 'Wird überprüft...',
			'setup.error' => 'Fehler',
			'setup.get' => 'Holen',
			'setup.startChatting' => 'Chat starten',
			'download.title' => ({required Object name}) => 'Download ${name}',
			'download.requiresAuth' => 'Dieses Modell erfordert einen HuggingFace-Zugang.',
			'download.hfToken' => 'HuggingFace Token',
			'download.hfTokenRequired' => 'HuggingFace Token erforderlich.',
			'download.downloading' => ({required Object progress}) => 'Wird heruntergeladen... ${progress}%',
			'download.startDownload' => 'Download starten',
			'download.noInternet' => 'Keine Internetverbindung erkannt.',
			'download.mobileDataWarningTitle' => 'Warnung vor großen Dateien',
			'download.mobileDataWarning' => 'Sie sind über mobile Daten verbunden. Dieses Modell ist eine große Datei (ca. 1-2 GB). Das Herunterladen kann viele Daten verbrauchen oder zusätzliche Kosten verursachen. Trotzdem fortfahren?',
			'download.proceed' => 'Fortfahren',
			'download.cancel' => 'Abbrechen',
			'download.downloadSuccess' => 'Modell erfolgreich heruntergeladen!',
			'download.downloadFailed' => ({required Object error}) => 'Download fehlgeschlagen: ${error}',
			'errors.contextOverflow' => '⚠️ Fehler: Die Eingabe überschreitet die strengen Hardware-Speichergrenzen. Das System hat versucht, den Speicher zu verkleinern, aber die Anfrage ist zu groß. Bitte erhöhen Sie das \'Gesamte Kontextfenster\' in den Einstellungen oder starten Sie einen neuen Chat.',
			'errors.inferenceFailed' => ({required Object error}) => '⚠️ Fehler: Modellinferenz fehlgeschlagen.\nDetails: ${error}',
			'errors.generationFailed' => ({required Object error}) => '⚠️ Fehler: Generierung konnte nicht gestartet werden.\nDetails: ${error}',
			'common.cancel' => 'Abbrechen',
			'common.delete' => 'Löschen',
			_ => null,
		};
	}
}
