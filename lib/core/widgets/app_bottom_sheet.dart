import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';

/// Feuille modale de l'application.
///
/// Deux APIs coexistaient — `Get.bottomSheet` (6 appels) et
/// `showModalBottomSheet` (5 appels) — chacune avec son propre rayon, sa propre
/// poignée dessinée à la main et sa propre gestion du clavier. Une seule ici.
class AppBottomSheet {
  const AppBottomSheet._();

  /// Durée de l'animation de fermeture.
  ///
  /// À attendre avant d'ouvrir une seconde feuille : les enchaîner sans délai
  /// laisse les deux dans l'arbre au même instant, ce qui produit des
  /// « Duplicate GlobalKeys » et des accès à un widget déjà désactivé.
  static const Duration closeAnimation = Duration(milliseconds: 300);

  /// Ouvre une feuille modale et retourne la valeur passée à `Get.back(result:)`.
  ///
  /// Le contenu est déjà rembourré, scrollable et remonté au-dessus du clavier
  /// — c'est le `viewInsets` que chaque appelant recalculait de son côté.
  static Future<T?> show<T>({
    required Widget child,
    String? title,
    bool isScrollControlled = true,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: Get.context!,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      backgroundColor: Colors.transparent,
      // Le Scaffold sous-jacent ne doit pas se redimensionner — la feuille
      // gère elle-même le décalage via viewInsets dans _SheetShell.
      useSafeArea: false,
      builder: (_) => _SheetShell(title: title, child: child),
    );
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: kBgCard,
            borderRadius: AppRadius.sheet,
          ),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kBorder,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (title != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title!,
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: kTextPrim,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                child,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
