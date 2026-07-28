import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';

/// Snackbars standardisés pour l'app propriétaire.
///
/// Usage :
///   AppSnackbar.error('Ce numéro est déjà utilisé.');
///   AppSnackbar.success('Terrain enregistré avec succès.');
///   AppSnackbar.info('Semaine limitée au contrôleur.');
///   AppSnackbar.warning('Ajoutez au moins un numéro de reversement.');
class AppSnackbar {
  AppSnackbar._();

  // ── Couleurs ────────────────────────────────────────────────────────────────
  // Issues de la palette : ces teintes étaient recopiées en hexadécimal ici, et
  // ne suivaient donc plus le thème.
  static const _kError = kRed;
  static const _kSuccess = kGreen;
  static const _kInfo = kBlue;
  static const _kWarning = kGoldDeep;

  // ── API publique ────────────────────────────────────────────────────────────

  /// Erreur — fond rouge, message simple et lisible.
  ///
  /// [onRetry] ajoute un bouton d'action. Pour un échec de chargement de page,
  /// préférez toutefois `AppErrorState` : un toast disparaît en 4 secondes et
  /// laisse l'utilisateur devant une liste vide sans moyen de réessayer.
  static void error(
    String message, {
    String? title,
    VoidCallback? onRetry,
    String retryLabel = 'Réessayer',
  }) => _show(
    title: title ?? 'Une erreur est survenue',
    message: message,
    background: _kError,
    icon: PhosphorIconsFill.warningCircle,
    duration: const Duration(seconds: 5),
    onAction: onRetry,
    actionLabel: retryLabel,
  );

  /// Succès — fond vert.
  static void success(String message, {String? title}) => _show(
    title: title ?? 'Succès',
    message: message,
    background: _kSuccess,
    icon: PhosphorIconsFill.checkCircle,
    duration: const Duration(seconds: 3),
  );

  /// Information — fond bleu.
  static void info(String message, {String? title}) => _show(
    title: title ?? 'Information',
    message: message,
    background: _kInfo,
    icon: PhosphorIconsFill.info,
    duration: const Duration(seconds: 3),
  );

  /// Avertissement — fond orange.
  static void warning(String message, {String? title}) => _show(
    title: title ?? 'Attention',
    message: message,
    background: _kWarning,
    icon: PhosphorIconsFill.warning,
    duration: const Duration(seconds: 4),
  );

  // ── Implémentation interne ──────────────────────────────────────────────────

  static void _show({
    required String title,
    required String message,
    required Color background,
    required IconData icon,
    required Duration duration,
    VoidCallback? onAction,
    String actionLabel = 'Réessayer',
  }) {
    // Fermer le snackbar précédent pour éviter l'empilement
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: background,
      colorText: Colors.white,
      borderRadius: AppRadius.md,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      duration: duration,
      animationDuration: const Duration(milliseconds: 300),
      icon: PhosphorIcon(icon, color: Colors.white, size: AppIconBox.mdIcon),
      mainButton: onAction == null
          ? null
          : TextButton(
              onPressed: () {
                Get.closeCurrentSnackbar();
                onAction();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text(
                actionLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
      boxShadows: [
        BoxShadow(
          color: background.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
