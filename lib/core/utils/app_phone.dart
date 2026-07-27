import '../config/app_config.dart';

/// Normalisation et validation des numéros de téléphone.
///
/// Les utilisateurs saisissent le même numéro de dix façons — avec des espaces,
/// avec l'indicatif, avec un 0 local, collé depuis un contact. Un champ qui
/// refuse silencieusement un format qu'il propose lui-même en exemple est un
/// blocage, pas une validation : tout ce qui est déchiffrable doit passer.
class AppPhone {
  const AppPhone._();

  /// Nombre de chiffres d'un numéro national sénégalais (ex. `771272788`).
  static const int nationalLength = 9;

  /// Normalise vers E.164 (`+221771272788`), ou `null` si inexploitable.
  ///
  /// Accepte `+221 77 127 27 88`, `00221771272788`, `0771272788`,
  /// `771272788`, `221771272788`.
  static String? normalize(String? raw) {
    if (raw == null) return null;

    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    final code = AppConfig.defaultCountryCode;

    // `00` est le préfixe international composé, équivalent du `+`.
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith(code)) digits = digits.substring(code.length);
    // `0` local : il remplace l'indicatif, il ne s'y ajoute pas.
    if (digits.startsWith('0')) digits = digits.substring(1);

    if (digits.length != nationalLength) return null;

    return '+$code$digits';
  }

  static bool isValid(String? raw) => normalize(raw) != null;

  /// Mise en forme lisible : `+221 77 127 27 88`.
  ///
  /// Retourne l'entrée telle quelle si elle n'est pas normalisable, pour ne
  /// jamais masquer une donnée existante à l'affichage.
  static String format(String? raw) {
    final e164 = normalize(raw);
    if (e164 == null) return raw ?? '';

    final code = AppConfig.defaultCountryCode;
    final n = e164.substring(code.length + 1); // 9 chiffres
    return '+$code ${n.substring(0, 2)} ${n.substring(2, 5)} '
        '${n.substring(5, 7)} ${n.substring(7)}';
  }
}
