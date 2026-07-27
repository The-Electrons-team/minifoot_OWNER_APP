import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_theme.dart';

/// Image distante, mise en cache.
///
/// `cached_network_image` était déclaré dans `pubspec.yaml` mais **jamais
/// importé** : les photos de terrain et les avatars passaient par
/// `Image.network`, donc étaient retéléchargées à chaque reconstruction et à
/// chaque défilement. Sur un forfait mobile sénégalais, c'est une dépense
/// inutile — et une image blanche à chaque scroll.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
    this.fallbackIcon = PhosphorIconsRegular.image,
  });

  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Affiché si l'URL est vide ou si le chargement échoue. À défaut, une icône
  /// neutre — jamais rien : une image qui disparaît sans trace laisse croire à
  /// un bug d'affichage.
  final Widget? fallback;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final image = (url == null || url!.isEmpty)
        ? _fallback()
        : CachedNetworkImage(
            imageUrl: url!,
            width: width,
            height: height,
            fit: fit,
            fadeInDuration: const Duration(milliseconds: 200),
            placeholder: (_, _) => _placeholder(),
            errorWidget: (_, _, _) => _fallback(),
          );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: kBgSurface,
  );

  Widget _fallback() =>
      fallback ??
      Container(
        width: width,
        height: height,
        color: kBgSurface,
        alignment: Alignment.center,
        child: Icon(fallbackIcon, color: kTextLight, size: 28),
      );
}

/// Avatar circulaire mis en cache, avec repli sur les initiales.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.url,
    required this.initials,
    this.size = 48,
    this.background = kGreenLight,
    this.foreground = kGreen,
  });

  final String? url;
  final String initials;
  final double size;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: AppNetworkImage(
        url: url,
        width: size,
        height: size,
        fallback: Container(
          width: size,
          height: size,
          color: background,
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.36,
            ),
          ),
        ),
      ),
    );
  }
}
