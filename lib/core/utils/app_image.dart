import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Préparation des images avant envoi.
///
/// Les photos partaient telles que sorties de l'appareil : plusieurs mégaoctets
/// et 4000 px de large, pour être affichées dans une carte de 140 px. Sur une
/// connexion mobile sénégalaise, un propriétaire qui ajoute cinq photos de
/// terrain paie plusieurs dizaines de mégaoctets pour rien — et l'envoi expire
/// souvent avant d'aboutir.
class AppImage {
  const AppImage._();

  /// Côté le plus long après redimensionnement.
  static const int maxDimension = 1600;

  /// Qualité JPEG. 82 est le seuil habituel au-delà duquel le gain de poids
  /// ne se voit plus à l'œil.
  static const int quality = 82;

  /// Compresse [file] et retourne le fichier allégé.
  ///
  /// Retourne l'original si la compression échoue ou ne fait pas gagner de
  /// place : mieux vaut envoyer une grosse image qu'échouer à en envoyer une.
  static Future<File> compress(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final target =
          '${dir.path}/minifoot_${DateTime.now().microsecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        target,
        minWidth: maxDimension,
        minHeight: maxDimension,
        quality: quality,
        // Sans cela, une photo prise en mode portrait arrive couchée côté
        // serveur : l'orientation EXIF n'est pas toujours respectée à l'affichage.
        autoCorrectionAngle: true,
      );

      if (result == null) return file;

      final compressed = File(result.path);
      if (await compressed.length() >= await file.length()) return file;

      return compressed;
    } on UnimplementedError {
      // Plugin natif absent du binaire : cas typique d'une app lancée avant
      // l'ajout de la dépendance (un `flutter run` complet suffit), ou d'une
      // plateforme non prise en charge. L'image part non compressée.
      debugPrint(
        'Compression indisponible sur cette plateforme — image envoyée telle '
        'quelle. Relancez un build complet si la dépendance vient d\'être ajoutée.',
      );
      return file;
    } catch (e) {
      debugPrint('Compression image ignorée: $e');
      return file;
    }
  }
}
