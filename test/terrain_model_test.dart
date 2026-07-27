import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foot_owner_flutter/features/terrain/controllers/terrain_controller.dart';

void main() {
  test('TerrainModel parses sub-terrains from backend payload', () {
    final terrain = TerrainModel.fromJson({
      'id': 'terrain-1',
      'name': 'Parcelle Sacre-Coeur',
      'address': 'Dakar',
      'pricePerHour': 15000,
      'zone': 'DAKAR',
      'features': ['Eclairage'],
      'imageUrls': <String>[],
      'rating': 4.5,
      'isActive': true,
      'subTerrains': [
        {
          'id': 'sub-1',
          'name': 'Terrain A',
          'capacity': 10,
          'type': '5v5',
          'surface': 'Gazon synthetique',
          'pricePerHour': 18000,
          'isActive': true,
        },
      ],
    });

    expect(terrain.miniTerrainCount, 1);
    // Renommé `reservableUnitLabel` (et le libellé est passé à « option ») ;
    // le test référençait encore l'ancien nom et cassait la compilation de
    // toute la suite, pas seulement de ce fichier.
    expect(terrain.reservableUnitLabel, '1 option');
    expect(terrain.subTerrains.first.name, 'Terrain A');
    // Le modèle a gagné la découpe (FULL/HALF) et les plages tarifaires depuis
    // l'écriture de ce test.
    expect(terrain.subTerrains.first.toJson(), {
      'id': 'sub-1',
      'name': 'Terrain A',
      'divisionType': 'FULL',
      'divisionIndex': 0,
      'capacity': 10,
      'type': '5v5',
      'surface': 'Gazon synthetique',
      'pricePerHour': 18000,
      'pricingPeriods': <Map<String, dynamic>>[],
      'isActive': true,
    });
  });
}
