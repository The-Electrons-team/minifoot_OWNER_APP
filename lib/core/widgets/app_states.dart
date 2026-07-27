import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_theme.dart';
import 'app_button.dart';

/// État vide d'une liste.
///
/// Chaque écran réécrivait sa propre colonne icône + titre + sous-titre, avec
/// des tons différents (l'écran Disponibilités tutoyait, les autres vouvoyaient)
/// et, le plus souvent, **sans action** : « Ajoute une personne de confiance »
/// s'affichait sans bouton pour le faire.
class AppEmptyState extends StatelessWidget {
  /// Icône employée quand l'appelant n'en précise aucune.
  // Variante Regular : les icônes Duotone ont un type propre
  // (`PhosphorDuotoneIconData`) qui n'est pas un `IconData`.
  static const IconData defaultIcon = PhosphorIconsRegular.tray;

  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = defaultIcon,
    this.actionLabel,
    this.onAction,
    this.illustration,
  });

  final String title;
  final String? message;
  final IconData icon;

  /// Un état vide sans porte de sortie est un cul-de-sac : dès qu'une action
  /// est possible, proposez-la ici.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Remplace l'icône, pour les écrans qui affichent une animation Lottie.
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            illustration ?? Icon(icon, size: 56, color: kTextLight),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextPrim,
                fontSize: AppFontSize.title,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kTextSub,
                  fontSize: AppFontSize.bodySmall,
                  height: 1.4,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// État d'erreur, avec bouton de reprise.
///
/// Sans lui, un échec de chargement s'affichait comme une liste vide : après
/// une coupure réseau, l'écran annonçait « Aucun terrain — Ajoutez votre
/// premier terrain » à un propriétaire qui en a cinq.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.title = 'Chargement impossible',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              PhosphorIconsRegular.warningCircle,
              size: 56,
              color: kTextLight,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextPrim,
                fontSize: AppFontSize.bodyLarge,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextSub,
                fontSize: AppFontSize.bodySmall,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Réessayer',
                icon: PhosphorIconsRegular.arrowClockwise,
                onPressed: onRetry,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
