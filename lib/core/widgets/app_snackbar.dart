import 'package:flutter/material.dart';
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
  static const _kError   = Color(0xFFDC2626); // rouge vif
  static const _kSuccess = Color(0xFF006F39); // vert principal
  static const _kInfo    = Color(0xFF1565C0); // bleu info
  static const _kWarning = Color(0xFFD97706); // orange avertissement

  // ── API publique ────────────────────────────────────────────────────────────

  /// Erreur — fond rouge, message simple et lisible.
  static void error(String message, {String? title}) => _show(
        title: title ?? 'Une erreur est survenue',
        message: message,
        background: _kError,
        icon: Icons.error_rounded,
        duration: const Duration(seconds: 4),
      );

  /// Succès — fond vert.
  static void success(String message, {String? title}) => _show(
        title: title ?? 'Succès',
        message: message,
        background: _kSuccess,
        icon: Icons.check_circle_rounded,
        duration: const Duration(seconds: 3),
      );

  /// Information — fond bleu.
  static void info(String message, {String? title}) => _show(
        title: title ?? 'Information',
        message: message,
        background: _kInfo,
        icon: Icons.info_rounded,
        duration: const Duration(seconds: 3),
      );

  /// Avertissement — fond orange.
  static void warning(String message, {String? title}) => _show(
        title: title ?? 'Attention',
        message: message,
        background: _kWarning,
        icon: Icons.warning_rounded,
        duration: const Duration(seconds: 4),
      );

  // ── Implémentation interne ──────────────────────────────────────────────────

  static void _show({
    required String title,
    required String message,
    required Color background,
    required IconData icon,
    required Duration duration,
  }) {
    // Fermer le snackbar précédent pour éviter l'empilement
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: background,
      colorText: Colors.white,
      borderRadius: 14,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      duration: duration,
      animationDuration: const Duration(milliseconds: 300),
      icon: Icon(icon, color: Colors.white, size: 24),
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          fontFamily: 'DMSans',
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: 'DMSans',
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
