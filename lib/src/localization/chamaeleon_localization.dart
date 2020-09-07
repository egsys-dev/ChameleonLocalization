import 'package:flutter/material.dart';
import '../from_file.dart';

///Este é o helperer usado pelo Delegate [ChamaleonLocalizationsDelegate]
/// pra carregar as strings e disponibilizar elas pros widgets através de
/// [ChamaleonLocalizations.of(context)]
class ChamaleonLocalizations with MapFromFileYaml {
  //locale no qual esta sendo carregado.
  final Locale currentLocale;

  ChamaleonLocalizations(this.currentLocale);

  static ChamaleonLocalizations of(BuildContext context) {
    return Localizations.of(context, ChamaleonLocalizations);
  }

  ///Map da representacao do JSON atual (baseado no flavor + idioma)
  dynamic _localizedStringsMain;
  dynamic _localizedStringsClient;

  ///
  ///Irá carregar no [_localizedStrings] os texto necessários, de acordo com
  ///o [flavorPrefix] passado de parametro idioma informado ao SO.
  ///
  Future<bool> init({String flavorPrefix}) async {
    //primeiro carrega as strings padrao do sistema, na lingua definida
    //pelo dispositivo
    _localizedStringsMain =
        await mapFromYaml('lang/${currentLocale.languageCode}.yaml');
    if (flavorPrefix != null) {
      //depois carrega as strings do flavor do sistema, na lingua definida.
      _localizedStringsClient = await mapFromYaml(
          'lang/$flavorPrefix/${currentLocale.languageCode}.yaml');
    }
    return true;
  }

  void clear() {
    _localizedStringsMain = null;
    _localizedStringsClient = null;
  }

  ///obtem o texto traduzido e retorna.
  ///é obrigado a ter o texto que esta sendo solicitado via chave
  ///caso não exista irá gerar um erro (assertiva)
  String translate(String key) {
    String text = getYamlValue(key, _localizedStringsClient);
    text ??= getYamlValue(key, _localizedStringsMain);

    assert(text != null,
        "The $key is not present in ${currentLocale.languageCode}.yaml ");

    return text;
  }
}

///Esse é o delegate usado pra configurar no MaterialApp os localization
///do sistema.
///
///Ele tem como objetivo suportar tanto localization quanto
///a troca de textos em flavores.
class ChamaleonLocalizationsDelegate
    extends LocalizationsDelegate<ChamaleonLocalizations> {
  ///Prefixo do flavor, é baseado nele que sera carregado as strings
  final String flavorPrefix;

  ///pra informar quais os locales são permitidos no app,
  ///caso definir um idioma não suportado será adotado a regra definida no
  ///widget [MaterialApp.localeResolutionCallback]
  final Iterable<Locale> supportedLocales;

  const ChamaleonLocalizationsDelegate(
      {@required this.flavorPrefix, @required this.supportedLocales});

  @override
  bool isSupported(Locale locale) => supportedLocales
      .any((supLocale) => supLocale.languageCode == locale.languageCode);

  @override
  Future<ChamaleonLocalizations> load(Locale locale) async {
    ChamaleonLocalizations localizations = ChamaleonLocalizations(locale);
    await localizations.init(flavorPrefix: flavorPrefix);
    return localizations;
  }

  @override
  bool shouldReload(LocalizationsDelegate<ChamaleonLocalizations> old) => false;
}

///Estrategia padrao para definir um locale.
///Caso não encontre um locale irá definir o primeiro da lista
///como sendo o locale atual
Locale localeResolutionCallback(
    Locale local, Iterable<Locale> supportedLocales) {
  for (final supportedLocale in supportedLocales) {
    if (local != null &&
        supportedLocale.languageCode == local.languageCode &&
        supportedLocale.countryCode == local.countryCode) {
      return supportedLocale;
    }
  }

  //por padrao retorna o primeiro locale suportado.
  return supportedLocales.first;
}

extension LocalizedString on String {
  String tr(BuildContext context) =>
      ChamaleonLocalizations.of(context).translate(this);
}
