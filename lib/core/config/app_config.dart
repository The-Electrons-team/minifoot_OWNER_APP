import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration centrale de l'application.
///
/// Point d'entrée unique pour tout ce qui dépend de l'environnement : URL de
/// l'API, délais réseau, clés de stockage local, services de cartographie.
/// **Aucun service ne doit lire `dotenv` directement** — chaque valeur en dur
/// dupliquée dans un service finit par diverger le jour où l'URL change.
///
/// Chaque clé a une valeur de repli de production : un fichier `.env` absent
/// ou incomplet ne casse donc pas l'application.
class AppConfig {
  const AppConfig._();

  /// Lit une clé de `.env` en traitant la chaîne vide comme absente.
  ///
  /// Tolère un `.env` non chargé (absent du bundle) : `dotenv` lève dans ce
  /// cas, or aucune valeur de configuration ne doit pouvoir crasher l'app.
  static String? env(String key) {
    try {
      final value = dotenv.env[key]?.trim();
      if (value == null || value.isEmpty) return null;
      return value;
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // API
  // ══════════════════════════════════════════════════════════════════════════

  /// Racine du backend, sans préfixe ni slash final.
  static const String _defaultApiBaseUrl = 'https://api.assanediallo.com';

  /// Préfixe global déclaré côté NestJS (`app.setGlobalPrefix`).
  static const String apiPrefix = '/api/v1';

  /// Hôte du backend, ex. `https://api.assanediallo.com`.
  ///
  /// Se configure via `API_BASE_URL`. `API_URL` reste accepté pour ne pas
  /// casser les `.env` existants : s'il contient déjà le préfixe, il est
  /// retiré ici pour que [apiUrl] reste la seule source de vérité.
  static String get apiBaseUrl {
    var value = env('API_BASE_URL') ?? env('API_URL') ?? _defaultApiBaseUrl;
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    if (value.endsWith(apiPrefix)) {
      value = value.substring(0, value.length - apiPrefix.length);
    }
    return value;
  }

  /// Base de tous les appels REST, ex. `https://api.assanediallo.com/api/v1`.
  static String get apiUrl => '$apiBaseUrl$apiPrefix';

  /// Construit l'URL d'un endpoint.
  ///
  /// ```dart
  /// AppConfig.api('/reservations/owner/mine');
  /// AppConfig.api('/notifications', {'page': 1});   // les null sont ignorés
  /// ```
  static Uri api(String path, [Map<String, dynamic>? query]) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$apiUrl$normalized');
    if (query == null || query.isEmpty) return uri;

    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        for (final entry in query.entries)
          if (entry.value != null) entry.key: '${entry.value}',
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Délais réseau
  // ══════════════════════════════════════════════════════════════════════════

  /// Appels REST classiques.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// Appels devant répondre vite ou échouer (rafraîchissement de token).
  static const Duration shortTimeout = Duration(seconds: 10);

  /// Envoi de fichiers (avatar, photos de terrain, documents propriétaire).
  static const Duration uploadTimeout = Duration(seconds: 30);

  /// Services tiers de cartographie, plus lents et non critiques.
  static const Duration geocodingTimeout = Duration(seconds: 12);

  // ══════════════════════════════════════════════════════════════════════════
  // Stockage local (SharedPreferences)
  // ══════════════════════════════════════════════════════════════════════════

  static const String tokenKey = 'token';
  static const String refreshTokenKey = 'refreshToken';

  // ══════════════════════════════════════════════════════════════════════════
  // Cartographie
  // ══════════════════════════════════════════════════════════════════════════

  static String? get mapboxAccessToken => env('MAPBOX_ACCESS_TOKEN');

  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  /// Géocodage inverse : coordonnées vers adresse lisible.
  static Uri reverseGeocode(double latitude, double longitude) {
    return Uri.parse(
      '${env('NOMINATIM_URL') ?? _nominatimBaseUrl}/reverse'
      '?lat=$latitude&lon=$longitude&format=json',
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Divers
  // ══════════════════════════════════════════════════════════════════════════

  /// Indicatif appliqué aux numéros saisis sans indicatif pays.
  static const String defaultCountryCode = '221';

  /// Taille de page par défaut des listes paginées.
  static const int defaultPageSize = 20;
}
