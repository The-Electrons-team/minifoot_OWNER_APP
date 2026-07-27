import 'app_phone.dart';

/// Règles de validation partagées.
///
/// Une règle dupliquée finit toujours par diverger : la longueur minimale du
/// mot de passe valait 8 à l'inscription et 6 au reset, si bien qu'un compte
/// créé à 8 caractères pouvait être ramené à 6 — la règle la plus stricte ne
/// servait à rien.
class AppValidators {
  const AppValidators._();

  /// Longueur minimale d'un mot de passe, appliquée partout.
  static const int minPasswordLength = 8;

  static const String passwordHint = 'Minimum $minPasswordLength caractères';

  /// Retourne le message d'erreur, ou `null` si la valeur est acceptable.
  /// Signature compatible avec `TextFormField.validator`.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Mot de passe requis';
    if (v.length < minPasswordLength) {
      return 'Le mot de passe doit contenir au moins $minPasswordLength caractères';
    }
    return null;
  }

  static String? passwordConfirmation(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Confirmez le mot de passe';
    if (value != original) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  static String? phone(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Numéro requis';
    if (!AppPhone.isValid(value)) {
      return 'Numéro invalide — ${AppPhone.nationalLength} chiffres attendus';
    }
    return null;
  }

  static String? required(String? value, {String label = 'Ce champ'}) {
    if ((value ?? '').trim().isEmpty) return '$label est requis';
    return null;
  }

  /// Code OTP à 6 chiffres.
  static const int otpLength = 6;

  static String? otp(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Code requis';
    if (v.length != otpLength) return 'Le code contient $otpLength chiffres';
    return null;
  }
}
