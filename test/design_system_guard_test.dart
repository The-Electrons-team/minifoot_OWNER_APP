import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde-fous du design system.
///
/// `CLAUDE.md` énonce ces règles depuis le début, mais rien ne les faisait
/// respecter : le code avait dérivé jusqu'à 250 couleurs en dur et 78 icônes
/// Material. Une règle non vérifiée n'est pas une règle.
///
/// Ces tests sont volontairement des compteurs à seuil plutôt que des « zéro » :
/// la migration des écrans est progressive (Lot 5), et un seuil qui ne peut que
/// baisser empêche toute nouvelle dérive sans bloquer le travail en cours.
/// **Baissez le seuil à chaque écran migré.**
void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  int countMatches(RegExp pattern, {bool Function(String path)? skip}) {
    var total = 0;
    for (final file in dartFiles) {
      if (skip != null && skip(file.path)) continue;
      total += pattern.allMatches(file.readAsStringSync()).length;
    }
    return total;
  }

  test('aucune icône Material — tout passe par Phosphor', () {
    final count = countMatches(RegExp(r'(?<![A-Za-z])Icons\.[a-zA-Z_]+'));
    expect(
      count,
      0,
      reason: 'Utilisez PhosphorIcons* : $count occurrence(s) de Icons.* trouvée(s).',
    );
  });

  test('les couleurs en dur restent cantonnées aux écrans non migrés', () {
    // 247 → 34 après la migration du Lot 5. Ce qui reste sont des teintes
    // ponctuelles absentes de la palette (fonds de champs, dégradés d'écran
    // unique) : leur donner un nom global n'apporterait rien.
    const budget = 40;

    final count = countMatches(
      RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)'),
      skip: (path) => path.contains('core/theme/'),
    );

    expect(
      count,
      lessThanOrEqualTo(budget),
      reason:
          '$count couleurs en dur hors core/theme/ (budget : $budget). '
          'Utilisez les constantes de la palette.',
    );
  });

  test('les décorations inline ne repartent pas à la hausse', () {
    const budget = 295;

    final count = countMatches(
      RegExp(r'BoxDecoration\('),
      skip: (path) => path.contains('core/'),
    );

    expect(
      count,
      lessThanOrEqualTo(budget),
      reason:
          '$count BoxDecoration inline hors core/ (budget : $budget). '
          'Utilisez AppCard.',
    );
  });

  test('aucune couleur Material brute', () {
    // Le préfixe négatif évite de capturer `PdfColors.grey`, qui vient du
    // paquet `pdf` et n'a rien à voir avec la palette de l'interface.
    final count = countMatches(
      RegExp(
        r'(?<![A-Za-z])Colors\.'
        r'(red|green|blue|orange|grey|amber|purple|yellow|pink|teal|indigo)\b',
      ),
    );
    expect(
      count,
      0,
      reason: '$count couleur(s) Material brute(s) : utilisez la palette k*.',
    );
  });

  test('aucun bouton ne redéfinit sa forme', () {
    // 26 boutons portaient 5 rayons différents (12, 14, 16, 18, 20) alors que
    // le thème en impose un seul. Chaque surcharge est une divergence de plus.
    final pattern = RegExp(
      r'(ElevatedButton|OutlinedButton|TextButton|FilledButton)\.styleFrom\(',
    );

    final offenders = <String>[];
    for (final file in dartFiles) {
      if (file.path.contains('core/theme/')) continue;
      final source = file.readAsStringSync();

      for (final match in pattern.allMatches(source)) {
        // Parenthèses équilibrées pour délimiter le styleFrom.
        var depth = 0;
        var end = match.end - 1;
        for (var i = end; i < source.length; i++) {
          if (source[i] == '(') depth++;
          if (source[i] == ')') {
            depth--;
            if (depth == 0) {
              end = i;
              break;
            }
          }
        }
        if (source.substring(match.end, end).contains('shape:')) {
          offenders.add(file.path);
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Ces boutons redéfinissent leur forme au lieu d\'hériter du thème : '
          '${offenders.toSet().join(', ')}',
    );
  });
}
