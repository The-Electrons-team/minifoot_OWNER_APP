import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_theme.dart';

class OwnerSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const OwnerSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kTextPrim,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: kTextSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: kGreen,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class OwnerIntroCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget leading;
  final Color? accentColor;
  final Color? accentBackground;
  final Widget? trailing;

  const OwnerIntroCard({
    super.key,
    required this.title,
    required this.description,
    required this.leading,
    this.accentColor,
    this.accentBackground,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final background = accentBackground ?? kGreenLight;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: kCardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: leading),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kTextPrim,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: kTextSub,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

/// Cadre commun des feuilles modales Owner.
///
/// Les écrans utilisaient tantôt une feuille bord-à-bord, tantôt une carte
/// flottante avec des rayons différents. Ce cadre garde une marge respirante,
/// le même rayon et la même ombre, tout en laissant chaque écran choisir son
/// contenu et son propre handle.
class OwnerSheetFrame extends StatelessWidget {
  const OwnerSheetFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: padding.add(EdgeInsets.only(bottom: bottomInset)),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: AppRadius.lgAll,
        boxShadow: kElevatedShadow,
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

class PaymentBrandBadge extends StatelessWidget {
  final String method;
  final double size;
  final bool compact;

  const PaymentBrandBadge({
    super.key,
    required this.method,
    this.size = 46,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = method.toUpperCase();
    final meta = _brandMeta(normalized);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(compact ? 7 : 8),
      decoration: BoxDecoration(
        color: meta.background,
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        border: Border.all(color: meta.border),
      ),
      child: _brandAsset(normalized),
    );
  }

  Widget _brandAsset(String normalized) {
    switch (normalized) {
      case 'WAVE':
        return Image.asset('assets/images/wave_logo.webp', fit: BoxFit.contain);
      case 'ORANGE_MONEY':
      case 'ORANGE MONEY':
        return Image.asset(
          'assets/images/orange_money.png',
          fit: BoxFit.contain,
        );
      case 'FREE_MONEY':
      case 'YAS_MONEY':
      case 'YAS MONEY':
        return SvgPicture.asset(
          'assets/images/yas_money.svg',
          fit: BoxFit.contain,
        );
      default:
        return PhosphorIcon(
          PhosphorIconsDuotone.creditCard,
          color: kTextSub,
          size: 22,
        );
    }
  }

  _PaymentBrandMeta _brandMeta(String normalized) {
    switch (normalized) {
      case 'WAVE':
        return const _PaymentBrandMeta(
          background: kWaveSurface,
          border: kWaveBorder,
        );
      case 'ORANGE_MONEY':
      case 'ORANGE MONEY':
        return const _PaymentBrandMeta(
          background: kOrangeMoneySurface,
          border: kOrangeMoneyBorder,
        );
      case 'FREE_MONEY':
      case 'YAS_MONEY':
      case 'YAS MONEY':
        return const _PaymentBrandMeta(
          background: kYasMoneySurface,
          border: kYasMoneyBorder,
        );
      default:
        return const _PaymentBrandMeta(background: kBgSurface, border: kBorder);
    }
  }
}

class _PaymentBrandMeta {
  final Color background;
  final Color border;

  const _PaymentBrandMeta({required this.background, required this.border});
}
