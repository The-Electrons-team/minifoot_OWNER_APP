import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foot_owner_flutter/core/config/app_config.dart';

void main() {
  group('AppConfig.apiUrl', () {
    test('utilise la production quand .env ne définit rien', () {
      dotenv.testLoad(fileInput: '');

      expect(AppConfig.apiBaseUrl, 'https://api.assanediallo.com');
      expect(AppConfig.apiUrl, 'https://api.assanediallo.com/api/v1');
    });

    test('ajoute le préfixe à API_BASE_URL', () {
      dotenv.testLoad(fileInput: 'API_BASE_URL=http://10.0.2.2:3000');

      expect(AppConfig.apiUrl, 'http://10.0.2.2:3000/api/v1');
    });

    test('ignore un slash final', () {
      dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.exemple.com/');

      expect(AppConfig.apiUrl, 'https://api.exemple.com/api/v1');
    });

    test('ne double pas le préfixe avec un API_URL hérité', () {
      // Les anciens .env contenaient l'URL complète : le préfixe est retiré
      // puis rajouté, le résultat doit être identique à l'entrée.
      dotenv.testLoad(fileInput: 'API_URL=https://api.exemple.com/api/v1');

      expect(AppConfig.apiUrl, 'https://api.exemple.com/api/v1');
    });

    test('API_BASE_URL prime sur API_URL', () {
      dotenv.testLoad(
        fileInput: 'API_URL=https://ancien.exemple.com/api/v1\n'
            'API_BASE_URL=https://nouveau.exemple.com',
      );

      expect(AppConfig.apiUrl, 'https://nouveau.exemple.com/api/v1');
    });

    test('une valeur vide retombe sur la valeur par défaut', () {
      dotenv.testLoad(fileInput: 'API_BASE_URL=   ');

      expect(AppConfig.apiUrl, 'https://api.assanediallo.com/api/v1');
    });
  });

  group('AppConfig.api', () {
    setUp(() => dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.exemple.com'));

    test('construit une URL d’endpoint', () {
      expect(
        AppConfig.api('/reservations/owner/mine').toString(),
        'https://api.exemple.com/api/v1/reservations/owner/mine',
      );
    });

    test('tolère un chemin sans slash initial', () {
      expect(
        AppConfig.api('notifications').toString(),
        'https://api.exemple.com/api/v1/notifications',
      );
    });

    test('sérialise la query et ignore les valeurs nulles', () {
      final uri = AppConfig.api('/notifications', {'page': 2, 'status': null});

      expect(uri.queryParameters, {'page': '2'});
    });
  });

  group('AppConfig.reverseGeocode', () {
    test('cible Nominatim par défaut', () {
      dotenv.testLoad(fileInput: '');

      final uri = AppConfig.reverseGeocode(14.7645, -17.5042);

      expect(uri.host, 'nominatim.openstreetmap.org');
      expect(uri.queryParameters['lat'], '14.7645');
      expect(uri.queryParameters['lon'], '-17.5042');
      expect(uri.queryParameters['format'], 'json');
    });
  });
}
