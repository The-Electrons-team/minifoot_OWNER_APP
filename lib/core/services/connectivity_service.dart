import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

/// Suit l'état de la connexion réseau.
///
/// L'app n'en avait aucune notion : sur une coupure — courante en 3G au bord
/// d'un terrain — l'écran se vidait sans rien expliquer, et l'utilisateur
/// concluait qu'il n'avait pas de données.
///
/// Attention à ce que ce service dit exactement : il indique qu'une interface
/// réseau est active, **pas** que le serveur est joignable. Un portail Wi-Fi
/// captif est « connecté ». C'est un indice pour l'interface, jamais une
/// autorisation de sauter une requête.
class ConnectivityService extends GetxService {
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// `false` uniquement lorsqu'aucune interface réseau n'est disponible.
  final isOnline = true.obs;

  Future<ConnectivityService> init() async {
    await _refresh();
    _subscription = _connectivity.onConnectivityChanged.listen(_apply);
    return this;
  }

  Future<void> _refresh() async {
    try {
      _apply(await _connectivity.checkConnectivity());
    } catch (_) {
      // Plateforme sans plugin (tests, web restreint) : on suppose en ligne
      // plutôt que d'afficher une bannière hors-ligne à tort.
      isOnline.value = true;
    }
  }

  void _apply(List<ConnectivityResult> results) {
    isOnline.value =
        results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
