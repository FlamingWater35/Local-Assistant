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
class TranslationsFi with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsFi({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.fi,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fi>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsFi _root = this; // ignore: unused_field

	@override 
	TranslationsFi $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsFi(meta: meta ?? this.$meta);

	// Translations
	@override String get appTitle => 'Paikallinen Avustaja';
	@override late final _TranslationsChatFi chat = _TranslationsChatFi._(_root);
	@override late final _TranslationsAttachmentsFi attachments = _TranslationsAttachmentsFi._(_root);
	@override late final _TranslationsSettingsFi settings = _TranslationsSettingsFi._(_root);
	@override late final _TranslationsSetupFi setup = _TranslationsSetupFi._(_root);
	@override late final _TranslationsDownloadFi download = _TranslationsDownloadFi._(_root);
	@override late final _TranslationsErrorsFi errors = _TranslationsErrorsFi._(_root);
	@override late final _TranslationsCommonFi common = _TranslationsCommonFi._(_root);
}

// Path: chat
class _TranslationsChatFi implements TranslationsChatEn {
	_TranslationsChatFi._(this._root);

	final TranslationsFi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Paikallinen Tekoälyavustaja';
	@override String get newChat => 'Uusi Keskustelu';
	@override String get recentHistory => 'Viimeisin Historia';
	@override String get settingsAndModels => 'Asetukset & Mallit';
	@override String get assistantName => 'Avustaja';
	@override String get userName => 'Minä';
	@override String get aiName => 'Paikallinen Tekoäly';
	@override String get deleteChatTitle => 'Poista Keskustelu';
	@override String deleteChatConfirm({required Object title}) => 'Oletko varma, että haluat poistaa keskustelun "${title}"?\nTätä ei voi peruuttaa.';
	@override String get deleteMessageTitle => 'Poista Viesti';
	@override String get deleteMessageConfirm => 'Oletko varma, että haluat poistaa tämän koko viestin ja sen liitteet?';
	@override String get chatDeleted => 'Keskustelu poistettu';
	@override String get messageDeleted => 'Viesti poistettu';
	@override String get maxAttachments => 'Enintään 2 liitettä sallittu viestiä kohden.';
	@override String get copyMessage => 'Kopioi viesti';
	@override String get copiedToClipboard => 'Kopioitu leikepöydälle';
	@override String get deleteMessage => 'Poista viesti';
	@override String get deleteMessageGroup => 'Poista viestiryhmä';
	@override String get composePrompt => 'Kirjoita Kehote';
	@override String get send => 'Lähetä';
	@override String get writePromptHint => 'Kirjoita yksityiskohtainen kehote tähän...';
	@override String get messageHint => 'Viesti Paikalliselle Avustajalle...';
	@override String get attachmentSession => 'Liiteistunto';
	@override String get generating => 'Luodaan...';
	@override String get stop => 'Pysäytä';
}

// Path: attachments
class _TranslationsAttachmentsFi implements TranslationsAttachmentsEn {
	_TranslationsAttachmentsFi._(this._root);

	final TranslationsFi _root; // ignore: unused_field

	// Translations
	@override String get photo => 'Kuva';
	@override String get audio => 'Ääni (.wav)';
	@override String get document => 'Asiakirja (.txt, .md, .csv)';
}

// Path: settings
class _TranslationsSettingsFi implements TranslationsSettingsEn {
	_TranslationsSettingsFi._(this._root);

	final TranslationsFi _root; // ignore: unused_field

	// Translations
	@override String get title => 'Asetukset';
	@override String get general => 'Yleiset';
	@override String get language => 'Kieli';
	@override String get systemLanguage => 'Järjestelmän oletus';
	@override String get aiModels => 'Tekoälymallit';
	@override String get inferenceAndMemory => 'Päättely ja Muisti';
	@override String get behavior => 'Käyttäytyminen';
	@override String get appUpdate => 'Sovelluksen Päivitys';
	@override String get readyToUse => 'Käyttövalmis';
	@override String get notDownloaded => 'Ei ladattu';
	@override String get checkingStatus => 'Tarkistetaan tilaa...';
	@override String get errorCheckingStatus => 'Virhe tilan tarkistuksessa';
	@override String get deleteModelTitle => 'Poista Malli';
	@override String deleteModelConfirm({required Object name}) => 'Oletko varma, että haluat poistaa mallin ${name}? Sinun on ladattava se uudelleen käyttääksesi sitä.';
	@override String get modelDeleted => 'Malli poistettu onnistuneesti';
	@override String get applyChanges => 'Tallenna Muutokset';
	@override String get settingsApplied => 'Asetukset otettu käyttöön';
	@override String get modelNotDownloaded => 'Valittua mallia ei ole ladattu!';
	@override String errorWithDetails({required Object details}) => 'Virhe: ${details}';
	@override String get enableMemoryTitle => 'Ota käyttöön muisti eri keskustelujen välillä';
	@override String get enableMemorySubtitle => 'Sallii tekoälyn hiljaisesti viitata asioihin muista viimeaikaisista keskusteluistasi.';
	@override String get totalContextWindow => 'Kokonaiskonteksti';
	@override String get contextWindowDescription => 'Laitteiston muisti syötteelle ja tulosteelle. Älykäs rajaus karsii automaattisesti vanhempia viestejä, kun raja on saavutettu.';
	@override String get tokens => 'Merkkejä';
	@override String get temperature => 'Lämpötila';
	@override String get temperatureDescription => 'Hallitsee luovuutta. Matalampi on keskitetympi, korkeampi on satunnaisempi.';
	@override String get systemInstructions => 'Järjestelmäohjeet';
	@override String get systemInstructionsDescription => 'Mukautetut ohjeet tekoälyn yleisen käyttäytymisen ja persoonan ohjaamiseen.';
	@override String get systemInstructionsHint => 'Olet avulias tekoälyavustaja.';
	@override String get checkForUpdates => 'Tarkista päivitykset';
	@override String get checkingForUpdates => 'Tarkistetaan päivityksiä...';
	@override String get appUpToDate => 'Sovellus on ajan tasalla';
	@override String get latestVersion => 'Käytät uusinta versiota';
	@override String updateAvailable({required Object version}) => 'Päivitys saatavilla: v${version}';
	@override String updateAvailableSnackbar({required Object version}) => 'Uusi päivitys (v${version}) on saatavilla. Tarkista Asetukset asentaaksesi.';
	@override String get tapToDownload => 'Napauta ladataksesi ja asentaaksesi';
	@override String get releaseNotes => 'Julkaisutiedot';
	@override String get downloadingUpdate => 'Ladataan päivitystä...';
	@override String percentComplete({required Object percent}) => '${percent}% valmis';
	@override String get updateCheckFailed => 'Päivityksen tarkistus epäonnistui';
	@override String get downloadModelTooltip => 'Lataa Malli';
	@override late final _TranslationsSettingsRamIndicatorFi ramIndicator = _TranslationsSettingsRamIndicatorFi._(_root);
}

// Path: setup
class _TranslationsSetupFi implements TranslationsSetupEn {
	_TranslationsSetupFi._(this._root);

	final TranslationsFi _root; // ignore: unused_field

	// Translations
	@override String get checkingSystem => 'Tarkistetaan järjestelmän tilaa...';
	@override String get startingModel => 'Käynnistetään Tekoälymallia...';
	@override String get welcomeTitle => 'Tervetuloa\nPaikalliseen Avustajaan';
	@override String get welcomeSubtitle => 'Aloittaaksesi, lataa tekoälymalli. Kaikki päättely tapahtuu paikallisesti ja yksityisesti laitteesi laitteistolla.';
	@override String get availableModels => 'SAATAVILLA OLEVAT MALLIT';
	@override String get downloaded => 'Ladattu';
	@override String get tapToDownload => 'Napauta ladataksesi';
	@override String get checking => 'Tarkistetaan...';
	@override String get error => 'Virhe';
	@override String get get => 'Hae';
	@override String get startChatting => 'Aloita Keskustelu';
}

// Path: download
class _TranslationsDownloadFi implements TranslationsDownloadEn {
	_TranslationsDownloadFi._(this._root);

	final TranslationsFi _root; // ignore: unused_field

	// Translations
	@override String title({required Object name}) => 'Lataa ${name}';
	@override String get requiresAuth => 'Tämä malli vaatii HuggingFace-pääsyn.';
	@override String get hfToken => 'HuggingFace-tunnus';
	@override String get hfTokenRequired => 'HuggingFace-tunnus vaaditaan.';
	@override String downloading({required Object progress}) => 'Ladataan... ${progress}%';
	@override String get startDownload => 'Aloita Lataus';
	@override String get noInternet => 'Internet-yhteyttä ei havaittu.';
	@override String get mobileDataWarningTitle => 'Varoitus isosta tiedostosta';
	@override String get mobileDataWarning => 'Olet yhteydessä mobiilidatalla. Tämä malli on iso tiedosto (noin 1-2 Gt) ja sen lataaminen voi kuluttaa merkittävästi dataa tai aiheuttaa lisämaksuja. Jatketaanko silti?';
	@override String get proceed => 'Jatka';
	@override String get cancel => 'Peruuta';
	@override String get downloadSuccess => 'Malli ladattiin onnistuneesti!';
	@override String downloadFailed({required Object error}) => 'Lataus epäonnistui: ${error}';
}

// Path: errors
class _TranslationsErrorsFi implements TranslationsErrorsEn {
	_TranslationsErrorsFi._(this._root);

	final TranslationsFi _root; // ignore: unused_field

	// Translations
	@override String get contextOverflow => '⚠️ Virhe: Syöte ylitti laitteiston muistirajoitukset. Järjestelmä yritti karsia muistia, mutta kehote on edelleen liian suuri. Kasvata \'Kokonaiskontekstia\' asetuksissa tai aloita uusi keskustelu.';
	@override String inferenceFailed({required Object error}) => '⚠️ Virhe: Mallin päättely epäonnistui.\nLisätietoja: ${error}';
	@override String generationFailed({required Object error}) => '⚠️ Virhe: Luonnin aloittaminen epäonnistui.\nLisätietoja: ${error}';
}

// Path: common
class _TranslationsCommonFi implements TranslationsCommonEn {
	_TranslationsCommonFi._(this._root);

	final TranslationsFi _root; // ignore: unused_field

	// Translations
	@override String get cancel => 'Peruuta';
	@override String get delete => 'Poista';
	@override String get recommended => 'Suositeltu';
}

// Path: settings.ramIndicator
class _TranslationsSettingsRamIndicatorFi implements TranslationsSettingsRamIndicatorEn {
	_TranslationsSettingsRamIndicatorFi._(this._root);

	final TranslationsFi _root; // ignore: unused_field

	// Translations
	@override String get unknown => 'Laitteen RAM: Tuntematon';
	@override String detected({required Object ram}) => 'Laitteen RAM: ${ram} GB';
	@override String get safe => '✅ Turvallinen laitteesi muistille.';
	@override String get warning => '⚠️ Suuri riski muistin loppumisvirheisiin tällä laitteella.';
}

/// The flat map containing all translations for locale <fi>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsFi {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appTitle' => 'Paikallinen Avustaja',
			'chat.title' => 'Paikallinen Tekoälyavustaja',
			'chat.newChat' => 'Uusi Keskustelu',
			'chat.recentHistory' => 'Viimeisin Historia',
			'chat.settingsAndModels' => 'Asetukset & Mallit',
			'chat.assistantName' => 'Avustaja',
			'chat.userName' => 'Minä',
			'chat.aiName' => 'Paikallinen Tekoäly',
			'chat.deleteChatTitle' => 'Poista Keskustelu',
			'chat.deleteChatConfirm' => ({required Object title}) => 'Oletko varma, että haluat poistaa keskustelun "${title}"?\nTätä ei voi peruuttaa.',
			'chat.deleteMessageTitle' => 'Poista Viesti',
			'chat.deleteMessageConfirm' => 'Oletko varma, että haluat poistaa tämän koko viestin ja sen liitteet?',
			'chat.chatDeleted' => 'Keskustelu poistettu',
			'chat.messageDeleted' => 'Viesti poistettu',
			'chat.maxAttachments' => 'Enintään 2 liitettä sallittu viestiä kohden.',
			'chat.copyMessage' => 'Kopioi viesti',
			'chat.copiedToClipboard' => 'Kopioitu leikepöydälle',
			'chat.deleteMessage' => 'Poista viesti',
			'chat.deleteMessageGroup' => 'Poista viestiryhmä',
			'chat.composePrompt' => 'Kirjoita Kehote',
			'chat.send' => 'Lähetä',
			'chat.writePromptHint' => 'Kirjoita yksityiskohtainen kehote tähän...',
			'chat.messageHint' => 'Viesti Paikalliselle Avustajalle...',
			'chat.attachmentSession' => 'Liiteistunto',
			'chat.generating' => 'Luodaan...',
			'chat.stop' => 'Pysäytä',
			'attachments.photo' => 'Kuva',
			'attachments.audio' => 'Ääni (.wav)',
			'attachments.document' => 'Asiakirja (.txt, .md, .csv)',
			'settings.title' => 'Asetukset',
			'settings.general' => 'Yleiset',
			'settings.language' => 'Kieli',
			'settings.systemLanguage' => 'Järjestelmän oletus',
			'settings.aiModels' => 'Tekoälymallit',
			'settings.inferenceAndMemory' => 'Päättely ja Muisti',
			'settings.behavior' => 'Käyttäytyminen',
			'settings.appUpdate' => 'Sovelluksen Päivitys',
			'settings.readyToUse' => 'Käyttövalmis',
			'settings.notDownloaded' => 'Ei ladattu',
			'settings.checkingStatus' => 'Tarkistetaan tilaa...',
			'settings.errorCheckingStatus' => 'Virhe tilan tarkistuksessa',
			'settings.deleteModelTitle' => 'Poista Malli',
			'settings.deleteModelConfirm' => ({required Object name}) => 'Oletko varma, että haluat poistaa mallin ${name}? Sinun on ladattava se uudelleen käyttääksesi sitä.',
			'settings.modelDeleted' => 'Malli poistettu onnistuneesti',
			'settings.applyChanges' => 'Tallenna Muutokset',
			'settings.settingsApplied' => 'Asetukset otettu käyttöön',
			'settings.modelNotDownloaded' => 'Valittua mallia ei ole ladattu!',
			'settings.errorWithDetails' => ({required Object details}) => 'Virhe: ${details}',
			'settings.enableMemoryTitle' => 'Ota käyttöön muisti eri keskustelujen välillä',
			'settings.enableMemorySubtitle' => 'Sallii tekoälyn hiljaisesti viitata asioihin muista viimeaikaisista keskusteluistasi.',
			'settings.totalContextWindow' => 'Kokonaiskonteksti',
			'settings.contextWindowDescription' => 'Laitteiston muisti syötteelle ja tulosteelle. Älykäs rajaus karsii automaattisesti vanhempia viestejä, kun raja on saavutettu.',
			'settings.tokens' => 'Merkkejä',
			'settings.temperature' => 'Lämpötila',
			'settings.temperatureDescription' => 'Hallitsee luovuutta. Matalampi on keskitetympi, korkeampi on satunnaisempi.',
			'settings.systemInstructions' => 'Järjestelmäohjeet',
			'settings.systemInstructionsDescription' => 'Mukautetut ohjeet tekoälyn yleisen käyttäytymisen ja persoonan ohjaamiseen.',
			'settings.systemInstructionsHint' => 'Olet avulias tekoälyavustaja.',
			'settings.checkForUpdates' => 'Tarkista päivitykset',
			'settings.checkingForUpdates' => 'Tarkistetaan päivityksiä...',
			'settings.appUpToDate' => 'Sovellus on ajan tasalla',
			'settings.latestVersion' => 'Käytät uusinta versiota',
			'settings.updateAvailable' => ({required Object version}) => 'Päivitys saatavilla: v${version}',
			'settings.updateAvailableSnackbar' => ({required Object version}) => 'Uusi päivitys (v${version}) on saatavilla. Tarkista Asetukset asentaaksesi.',
			'settings.tapToDownload' => 'Napauta ladataksesi ja asentaaksesi',
			'settings.releaseNotes' => 'Julkaisutiedot',
			'settings.downloadingUpdate' => 'Ladataan päivitystä...',
			'settings.percentComplete' => ({required Object percent}) => '${percent}% valmis',
			'settings.updateCheckFailed' => 'Päivityksen tarkistus epäonnistui',
			'settings.downloadModelTooltip' => 'Lataa Malli',
			'settings.ramIndicator.unknown' => 'Laitteen RAM: Tuntematon',
			'settings.ramIndicator.detected' => ({required Object ram}) => 'Laitteen RAM: ${ram} GB',
			'settings.ramIndicator.safe' => '✅ Turvallinen laitteesi muistille.',
			'settings.ramIndicator.warning' => '⚠️ Suuri riski muistin loppumisvirheisiin tällä laitteella.',
			'setup.checkingSystem' => 'Tarkistetaan järjestelmän tilaa...',
			'setup.startingModel' => 'Käynnistetään Tekoälymallia...',
			'setup.welcomeTitle' => 'Tervetuloa\nPaikalliseen Avustajaan',
			'setup.welcomeSubtitle' => 'Aloittaaksesi, lataa tekoälymalli. Kaikki päättely tapahtuu paikallisesti ja yksityisesti laitteesi laitteistolla.',
			'setup.availableModels' => 'SAATAVILLA OLEVAT MALLIT',
			'setup.downloaded' => 'Ladattu',
			'setup.tapToDownload' => 'Napauta ladataksesi',
			'setup.checking' => 'Tarkistetaan...',
			'setup.error' => 'Virhe',
			'setup.get' => 'Hae',
			'setup.startChatting' => 'Aloita Keskustelu',
			'download.title' => ({required Object name}) => 'Lataa ${name}',
			'download.requiresAuth' => 'Tämä malli vaatii HuggingFace-pääsyn.',
			'download.hfToken' => 'HuggingFace-tunnus',
			'download.hfTokenRequired' => 'HuggingFace-tunnus vaaditaan.',
			'download.downloading' => ({required Object progress}) => 'Ladataan... ${progress}%',
			'download.startDownload' => 'Aloita Lataus',
			'download.noInternet' => 'Internet-yhteyttä ei havaittu.',
			'download.mobileDataWarningTitle' => 'Varoitus isosta tiedostosta',
			'download.mobileDataWarning' => 'Olet yhteydessä mobiilidatalla. Tämä malli on iso tiedosto (noin 1-2 Gt) ja sen lataaminen voi kuluttaa merkittävästi dataa tai aiheuttaa lisämaksuja. Jatketaanko silti?',
			'download.proceed' => 'Jatka',
			'download.cancel' => 'Peruuta',
			'download.downloadSuccess' => 'Malli ladattiin onnistuneesti!',
			'download.downloadFailed' => ({required Object error}) => 'Lataus epäonnistui: ${error}',
			'errors.contextOverflow' => '⚠️ Virhe: Syöte ylitti laitteiston muistirajoitukset. Järjestelmä yritti karsia muistia, mutta kehote on edelleen liian suuri. Kasvata \'Kokonaiskontekstia\' asetuksissa tai aloita uusi keskustelu.',
			'errors.inferenceFailed' => ({required Object error}) => '⚠️ Virhe: Mallin päättely epäonnistui.\nLisätietoja: ${error}',
			'errors.generationFailed' => ({required Object error}) => '⚠️ Virhe: Luonnin aloittaminen epäonnistui.\nLisätietoja: ${error}',
			'common.cancel' => 'Peruuta',
			'common.delete' => 'Poista',
			'common.recommended' => 'Suositeltu',
			_ => null,
		};
	}
}
