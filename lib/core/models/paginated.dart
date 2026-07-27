/// Page de résultats renvoyée par les listes paginées du backend.
///
/// Le backend répond `{data, total, page, limit, hasMore}`. Sans `hasMore`, le
/// client ne peut pas savoir s'il reste des éléments : c'est ce qui plafonnait
/// silencieusement chaque liste à sa première page.
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
  });

  final List<T> items;
  final int total;
  final int page;
  final bool hasMore;

  /// Construit depuis le corps de réponse.
  ///
  /// Tolère une réponse en liste nue : certains endpoints n'ont pas encore été
  /// migrés, et une mise à jour du backend ne doit pas faire planter l'app.
  factory Paginated.fromBody(dynamic body, {int page = 1}) {
    if (body is List) {
      return Paginated<T>(
        items: body.cast<T>(),
        total: body.length,
        page: 1,
        hasMore: false,
      );
    }

    if (body is Map<String, dynamic>) {
      final items = (body['data'] as List<dynamic>? ?? const []).cast<T>();
      final total = _asInt(body['total']) ?? items.length;
      return Paginated<T>(
        items: items,
        total: total,
        page: _asInt(body['page']) ?? page,
        // Si `hasMore` est absent (ancien backend), on le déduit du total.
        hasMore: body['hasMore'] as bool? ?? items.length < total,
      );
    }

    return Paginated<T>(items: const [], total: 0, page: page, hasMore: false);
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
