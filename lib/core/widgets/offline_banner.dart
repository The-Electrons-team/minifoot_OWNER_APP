import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';

/// Bandeau permanent affiché hors connexion.
///
/// Posé une fois au-dessus de toute l'app plutôt qu'écran par écran : la
/// coupure réseau ne dépend pas de la page où l'on se trouve.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConnectivityService>()) return child;
    final service = Get.find<ConnectivityService>();

    return Column(
      children: [
        Obx(() {
          final online = service.isOnline.value;
          return AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: online ? const SizedBox.shrink() : const _Bar(),
          );
        }),
        Expanded(child: child),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kTextPrim,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                PhosphorIconsFill.wifiSlash,
                color: Colors.white,
                size: AppIconBox.smIcon,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  'Pas de connexion — les données affichées peuvent être anciennes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppFontSize.caption,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
