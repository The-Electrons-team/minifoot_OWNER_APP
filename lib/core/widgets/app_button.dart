import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, danger }

/// Bouton principal de l'application.
///
/// Le style était re-spécifié à la main dans une dizaine d'écrans, avec trois
/// rayons différents (14, 16, 18) et autant de tailles de loader. Ce composant
/// centralise aussi deux choses qui manquaient partout :
///
/// * un état de chargement qui **empêche le double envoi** ;
/// * une explication quand le bouton est désactivé, au lieu d'un bouton grisé
///   muet devant lequel l'utilisateur reste bloqué.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.disabledHint,
    this.haptic = true,
  });

  final String label;

  /// `null` désactive le bouton.
  final VoidCallback? onPressed;

  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  /// Message affiché sous le bouton quand il est désactivé. Un bouton grisé
  /// sans explication est un cul-de-sac.
  final String? disabledHint;

  final bool haptic;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: expanded ? double.infinity : null,
      height: AppTouch.buttonHeight,
      child: _buildButton(),
    );

    if (_enabled || disabledHint == null) return button;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        button,
        const SizedBox(height: AppSpacing.xs),
        Text(
          disabledHint!,
          style: const TextStyle(
            fontSize: AppFontSize.caption,
            color: kTextSub,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildButton() {
    final onTap = _enabled
        ? () {
            if (haptic) HapticFeedback.selectionClick();
            onPressed!();
          }
        : null;

    if (variant == AppButtonVariant.secondary) {
      return OutlinedButton(onPressed: onTap, child: _child(kTextPrim));
    }

    return ElevatedButton(
      onPressed: onTap,
      style: variant == AppButtonVariant.danger
          ? ElevatedButton.styleFrom(
              backgroundColor: kRed,
              disabledBackgroundColor: kRed.withValues(alpha: 0.5),
            )
          : null,
      child: _child(Colors.white),
    );
  }

  Widget _child(Color foreground) {
    if (loading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(foreground),
        ),
      );
    }

    if (icon == null) return Text(label);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
