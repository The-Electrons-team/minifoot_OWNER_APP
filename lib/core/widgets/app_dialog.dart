import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';

/// Dialogues de confirmation de l'application.
///
/// Remplace le mélange `Get.dialog` / `Get.defaultDialog` : ce dernier rend le
/// chrome par défaut de GetX, sans les polices de l'app et **sans couleur
/// destructive** — « Supprimer » s'affichait en vert, comme une validation.
class AppDialog {
  const AppDialog._();

  /// Demande une confirmation. Retourne `true` si l'utilisateur confirme.
  ///
  /// [destructive] passe l'action de confirmation en rouge : une suppression ne
  /// doit pas ressembler à une validation.
  static Future<bool> confirm({
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    bool destructive = false,
  }) async {
    if (destructive) HapticFeedback.heavyImpact();

    final result = await Get.dialog<bool>(
      _ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
      ),
      barrierDismissible: true,
    );
    return result ?? false;
  }

  /// Confirmation d'abandon d'une saisie en cours.
  ///
  /// Le bouton retour matériel détruisait jusqu'ici un assistant de plusieurs
  /// étapes sans le moindre avertissement.
  static Future<bool> confirmDiscard({
    String message = 'Les informations saisies seront perdues.',
  }) => confirm(
    title: 'Abandonner la saisie ?',
    message: message,
    confirmLabel: 'Abandonner',
    cancelLabel: 'Continuer',
    destructive: true,
  );
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? kRed : kGreen;

    return Dialog(
      backgroundColor: kBgCard,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: kTextPrim,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: kTextSub,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  style: TextButton.styleFrom(
                    foregroundColor: kTextSub,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    cancelLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Get.back(result: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    confirmLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
