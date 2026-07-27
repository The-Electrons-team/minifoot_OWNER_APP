/// Utilitaires d'exécution asynchrone.
class AppAsync {
  const AppAsync._();

  /// Nombre de requêtes menées de front par défaut.
  ///
  /// Assez pour effacer la latence d'un aller-retour sur 3G, assez peu pour ne
  /// pas saturer la connexion ni le serveur.
  static const int defaultConcurrency = 6;

  /// Applique [task] à chaque élément, par lots concurrents bornés.
  ///
  /// Une boucle `for` avec `await` paie la latence réseau une fois par
  /// élément : bloquer une plage de plusieurs jours de créneaux revenait à
  /// enchaîner des centaines d'aller-retours l'un après l'autre.
  ///
  /// L'ordre des résultats correspond à celui des éléments.
  static Future<List<R>> mapBounded<T, R>(
    List<T> items,
    Future<R> Function(T item) task, {
    int concurrency = defaultConcurrency,
  }) async {
    if (items.isEmpty) return <R>[];

    final size = concurrency < 1 ? 1 : concurrency;
    final results = <R>[];

    for (var i = 0; i < items.length; i += size) {
      final end = (i + size < items.length) ? i + size : items.length;
      final batch = items.sublist(i, end);
      results.addAll(await Future.wait(batch.map(task)));
    }

    return results;
  }
}
