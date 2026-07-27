import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';

/// Onglet courant de la coquille de navigation.
///
/// Remplace le `selectedTab` du tableau de bord, qui était remis à 0 au retour
/// de chaque route : la surbrillance était en écriture seule, elle ne reflétait
/// jamais l'écran affiché.
class ShellController extends GetxController {
  final currentIndex = 0.obs;

  bool get isController =>
      Get.find<AuthController>().user.value?.isController == true;

  void select(int index) => currentIndex.value = index;

  /// Ramène à l'accueil. Sur une coquille à onglets, le premier retour matériel
  /// doit revenir à l'accueil plutôt que quitter l'application.
  bool goHomeIfNeeded() {
    if (currentIndex.value == 0) return false;
    currentIndex.value = 0;
    return true;
  }
}
