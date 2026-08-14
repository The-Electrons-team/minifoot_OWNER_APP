import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/widgets/lazy_indexed_stack.dart';
import '../../../core/widgets/owner_bottom_nav.dart';
import '../../availability/controllers/availability_controller.dart';
import '../../availability/screens/availability_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../payments/controllers/payments_controller.dart';
import '../../payments/screens/payments_screen.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/screens/profile_screen.dart';
import '../../qr_checkin/controllers/qr_checkin_controller.dart';
import '../../qr_checkin/screens/qr_checkin_screen.dart';
import '../../reservations/controllers/reservations_controller.dart';
import '../../reservations/screens/reservations_screen.dart';
import '../../terrain/controllers/terrain_controller.dart';
import '../../terrain/screens/terrain_list_screen.dart';
import '../controllers/shell_controller.dart';

/// Coquille de navigation à onglets persistants.
///
/// Avant, la barre n'existait que dans le tableau de bord et chaque onglet
/// **empilait** une route par-dessus : la barre disparaissait au premier tap,
/// il fallait deux gestes pour passer d'un onglet à l'autre, et la pile de
/// navigation grossissait sans fin (accueil → terrains → accueil → paiements…).
///
/// Ici les cinq destinations vivent côte à côte : la barre reste affichée, un
/// tap suffit, et chaque onglet retrouve son défilement et ses filtres.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    // Le binding de route l'enregistre normalement, mais un hot reload ou une
    // reconstruction hors route peut le perdre : la coquille garantit sa
    // propre dépendance plutôt que de lever.
    if (!Get.isRegistered<ShellController>()) {
      Get.put<ShellController>(ShellController(), permanent: true);
    }
    final shell = Get.find<ShellController>();

    return Obx(() {
      final isController = shell.isController;

      // Le contrôleur de terrain et le propriétaire n'ont pas les mêmes
      // destinations : le premier gère créneaux et réservations, le second
      // ses terrains et ses paiements.
      final destinations = <OwnerNavDestination>[
        const OwnerNavDestination(
          icon: PhosphorIconsRegular.squaresFour,
          label: 'Accueil',
        ),
        OwnerNavDestination(
          icon: PhosphorIconsRegular.courtBasketball,
          label: isController ? 'Réserv.' : 'Terrains',
        ),
        const OwnerNavDestination(
          icon: PhosphorIconsRegular.qrCode,
          label: 'Scanner',
        ),
        OwnerNavDestination(
          icon: isController
              ? PhosphorIconsRegular.clockCountdown
              : PhosphorIconsRegular.wallet,
          label: isController ? 'Créneaux' : 'Paiements',
        ),
        const OwnerNavDestination(
          icon: PhosphorIconsRegular.user,
          label: 'Profil',
        ),
      ];

      return PopScope(
        // Depuis un onglet secondaire, le retour matériel revient à l'accueil
        // au lieu de fermer l'application.
        canPop: shell.currentIndex.value == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) shell.goHomeIfNeeded();
        },
        child: Scaffold(
          body: LazyIndexedStack(
            index: shell.currentIndex.value,
            itemCount: destinations.length,
            itemBuilder: (context, index) => _destination(index, isController),
          ),
          bottomNavigationBar: shell.currentIndex.value == 2
              ? null
              : OwnerBottomNav(
                  destinations: destinations,
                  currentIndex: shell.currentIndex.value,
                  centerIndex: 2,
                  centerLabel: 'Scanner un QR code de réservation',
                  onSelected: shell.select,
                ),
        ),
      );
    });
  }

  /// Instancie le contrôleur de la destination au moment où on l'affiche.
  ///
  /// Les `Bindings` sont liés aux routes ; la coquille n'en a plus, on met donc
  /// en place les dépendances ici — paresseusement, pour ne pas déclencher cinq
  /// chargements réseau au démarrage.
  Widget _destination(int index, bool isController) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        if (isController) {
          Get.lazyPut<ReservationsController>(() => ReservationsController());
          return const ReservationsScreen();
        }
        Get.lazyPut<TerrainController>(() => TerrainController());
        return const TerrainListScreen();
      case 2:
        Get.lazyPut<QrCheckInController>(() => QrCheckInController());
        return const QrCheckInScreen();
      case 3:
        if (isController) {
          Get.lazyPut<AvailabilityController>(() => AvailabilityController());
          return const AvailabilityScreen();
        }
        Get.lazyPut<PaymentsController>(() => PaymentsController());
        return const PaymentsScreen();
      default:
        Get.lazyPut<ProfileController>(() => ProfileController());
        return const ProfileScreen();
    }
  }
}
