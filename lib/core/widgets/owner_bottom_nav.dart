import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Une destination de la barre de navigation.
class OwnerNavDestination {
  const OwnerNavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Barre de navigation principale, en pilule flottante.
///
/// Elle vivait en méthode privée du tableau de bord : chaque « onglet »
/// empilait une route par-dessus, la barre disparaissait aussitôt, et l'onglet
/// actif était remis à zéro au retour — la surbrillance ne tenait jamais.
/// Extraite ici, elle est rendue une fois par la coquille et reste visible.
class OwnerBottomNav extends StatelessWidget {
  const OwnerBottomNav({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
    required this.centerIndex,
    required this.centerLabel,
  });

  final List<OwnerNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  /// Rang du bouton central en relief (le scan QR).
  final int centerIndex;

  /// Libellé lu par les lecteurs d'écran pour ce bouton, qui n'a pas de texte.
  final String centerLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              height: 68,
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: kNavShadow,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    if (i == centerIndex)
                      // Réserve la place du bouton central en relief.
                      const SizedBox(width: 72)
                    else
                      _NavItem(
                        destination: destinations[i],
                        isSelected: currentIndex == i,
                        onTap: () => onSelected(i),
                      ),
                ],
              ),
            ),
            Positioned(
              bottom: 20,
              child: Semantics(
                button: true,
                selected: currentIndex == centerIndex,
                // Le bouton n'affiche qu'une image de ballon : sans libellé, un
                // lecteur d'écran n'annonçait rien du tout.
                label: centerLabel,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(centerIndex);
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: kBgCard,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: currentIndex == centerIndex ? kGreen : kBorder,
                        width: 2,
                      ),
                      boxShadow: kCardShadow,
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: ExcludeSemantics(
                          child: Image.asset(
                            'assets/images/ballon.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final OwnerNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? kGreen : kTextLight;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: destination.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: ExcludeSemantics(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(destination.icon, color: color, size: AppIconBox.mdIcon),
                const SizedBox(height: AppSpacing.xxs),
                // `ellipsis` plutôt qu'un rognage sec : sur un écran de 320 pt
                // les quatre libellés se partagent ~52 pt chacun.
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: AppFontSize.caption,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
