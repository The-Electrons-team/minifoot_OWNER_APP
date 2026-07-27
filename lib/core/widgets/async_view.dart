import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../theme/app_theme.dart';
import 'app_states.dart';

/// Rend les quatre états d'un chargement : squelette, erreur, vide, données.
///
/// Trois vocabulaires de chargement coexistaient dans l'app — squelette maison,
/// spinner centré, fine barre de progression — et l'erreur était le plus souvent
/// indiscernable du vide. Ce composant impose un seul enchaînement.
///
/// ```dart
/// Obx(() => AsyncView(
///   isLoading: c.isLoading.value,
///   error: c.errorMessage.value,
///   isEmpty: c.terrains.isEmpty,
///   onRetry: c.refresh,
///   emptyTitle: 'Aucun terrain',
///   emptyMessage: 'Ajoutez votre premier terrain pour commencer.',
///   emptyActionLabel: 'Ajouter un terrain',
///   onEmptyAction: c.openForm,
///   skeleton: const TerrainCardSkeleton(),
///   child: ListView(...),
/// ));
/// ```
class AsyncView extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.isLoading,
    required this.child,
    this.error = '',
    this.isEmpty = false,
    this.onRetry,
    this.skeleton,
    this.emptyTitle = 'Rien à afficher',
    this.emptyMessage,
    this.emptyIcon,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.emptyIllustration,
  });

  final bool isLoading;

  /// Message d'erreur. Vide = pas d'erreur.
  final String error;

  final bool isEmpty;
  final VoidCallback? onRetry;

  /// Contenu réel, affiché quand tout va bien.
  final Widget child;

  /// Maquette grisée pendant le chargement. À défaut, [child] lui-même est
  /// grisé — `skeletonizer` dérive le squelette de la vraie mise en page, il
  /// n'y a donc plus de squelette à maintenir à part.
  final Widget? skeleton;

  final String emptyTitle;
  final String? emptyMessage;
  final IconData? emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final Widget? emptyIllustration;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Skeletonizer(
        enabled: true,
        effect: const ShimmerEffect(
          baseColor: kBgSurface,
          highlightColor: kBgCard,
        ),
        child: skeleton ?? child,
      );
    }

    // L'erreur passe avant le vide : une liste vide parce que la requête a
    // échoué ne doit jamais s'afficher comme « vous n'avez rien créé ».
    if (error.isNotEmpty) {
      return AppErrorState(message: error, onRetry: onRetry);
    }

    if (isEmpty) {
      return AppEmptyState(
        title: emptyTitle,
        message: emptyMessage,
        icon: emptyIcon ?? AppEmptyState.defaultIcon,
        illustration: emptyIllustration,
        actionLabel: emptyActionLabel,
        onAction: onEmptyAction,
      );
    }

    return child;
  }
}
