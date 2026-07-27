import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Carte standard de l'application.
///
/// La même `BoxDecoration` — fond blanc, rayon 18, `kCardShadow` — était
/// retapée une trentaine de fois. Toute évolution du style (rayon, ombre, mode
/// sombre) devait alors être répercutée à la main dans chaque écran.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.margin,
    this.onTap,
    this.color,
    this.borderColor,
    this.gradient,
    this.elevated = false,
    this.radius = AppRadius.md,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Rend la carte interactive. La zone de tap couvre toute la carte, pas
  /// seulement son contenu.
  final VoidCallback? onTap;

  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;

  /// Ombre plus marquée, pour un élément qui doit flotter au-dessus du reste.
  final bool elevated;

  final double radius;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? kBgCard) : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: elevated ? kElevatedShadow : kCardShadow,
      ),
      child: child,
    );

    if (onTap == null) {
      return margin == null ? content : Padding(padding: margin!, child: content);
    }

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      ),
    );
  }
}

/// Conteneur d'icône coloré, motif récurrent des cartes et des tuiles.
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = AppIconBox.md,
    this.iconSize,
    this.background,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double? iconSize;

  /// Par défaut, une teinte de [color] à 12 % — suffisant pour se détacher du
  /// fond de carte sans concurrencer le contenu.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.12),
        borderRadius: AppRadius.xsAll,
      ),
      child: Icon(icon, color: color, size: iconSize ?? size * 0.5),
    );
  }
}
