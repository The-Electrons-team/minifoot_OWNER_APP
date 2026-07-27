import 'package:get/get.dart';

import '../../dashboard/controllers/dashboard_controller.dart';
import '../controllers/shell_controller.dart';

/// Dépendances de la coquille de navigation.
///
/// Seuls la coquille et l'accueil sont instanciés ici : les autres onglets
/// enregistrent leur contrôleur à leur première ouverture (voir `AppShell`),
/// pour ne pas payer cinq chargements réseau au démarrage.
class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ShellController>(ShellController(), permanent: true);
    Get.lazyPut<DashboardController>(() => DashboardController());
  }
}
