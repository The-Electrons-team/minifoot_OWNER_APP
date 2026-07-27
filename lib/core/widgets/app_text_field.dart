import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Champ de saisie de l'application.
///
/// C'est un `TextFormField` : il participe donc à la validation d'un `Form`, et
/// **affiche l'erreur sous le champ concerné**. L'app n'avait jusqu'ici aucun
/// `Form` — toute erreur de saisie partait en snackbar en haut de l'écran, ce
/// qui, sur un formulaire de plusieurs pages, ne dit pas quel champ corriger.
///
/// Le libellé est rendu au-dessus du champ plutôt qu'en `labelText` flottant :
/// c'est le motif déjà employé partout dans l'app.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.icon,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;

  /// Consigne affichée sous le champ tant qu'il n'y a pas d'erreur.
  final String? helper;

  final IconData? icon;
  final Widget? suffix;

  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  /// À renseigner sur tout formulaire multi-champs pour que la touche du
  /// clavier passe au champ suivant.
  final TextInputAction? textInputAction;

  final List<TextInputFormatter>? inputFormatters;

  /// Indispensable pour le remplissage automatique — notamment
  /// `AutofillHints.oneTimeCode`, qui fait remplir le code reçu par SMS.
  final Iterable<String>? autofillHints;

  final bool obscureText;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      // La validation se déclenche dès que l'utilisateur touche au champ, pas
      // seulement à la soumission : il corrige au fil de la saisie.
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      obscureText: obscureText,
      enabled: enabled,
      maxLines: obscureText ? 1 : maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        fontSize: AppFontSize.body,
        color: kTextPrim,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        counterText: '',
        fillColor: enabled ? kBgCard : kBgSurface,
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: kTextSub, size: AppIconBox.smIcon),
        suffixIcon: suffix,
      ),
    );

    if (label == null) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label!,
          style: const TextStyle(
            color: kTextSub,
            fontSize: AppFontSize.bodySmall,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        field,
      ],
    );
  }
}
