import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foot_owner_flutter/core/theme/app_theme.dart';

/// Luminance relative WCAG 2.1.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // L'app s'utilise dehors, en plein soleil, au bord du terrain : le contraste
  // n'est pas une finition mais une condition de lisibilité. Ce test a invalidé
  // #6B7280 comme candidat pour kTextLight — il ne donnait que 4,26:1.
  const backgrounds = <String, Color>{
    'kBg': kBg,
    'kBgCard': kBgCard,
    'kBgSurface': kBgSurface,
  };

  const texts = <String, Color>{
    'kTextPrim': kTextPrim,
    'kTextSub': kTextSub,
    'kTextLight': kTextLight,
  };

  group('Contraste WCAG AA (4.5:1)', () {
    texts.forEach((textName, textColor) {
      backgrounds.forEach((bgName, bgColor) {
        test('$textName sur $bgName', () {
          final ratio = contrast(textColor, bgColor);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason:
                '$textName (${_hex(textColor)}) sur $bgName (${_hex(bgColor)}) '
                'donne ${ratio.toStringAsFixed(2)}:1 — sous le seuil AA.',
          );
        });
      });
    });
  });

  group('Couleurs d’état sur fond clair', () {
    for (final entry in {'kGreen': kGreen, 'kRed': kRed, 'kBlue': kBlue}.entries) {
      test('${entry.key} lisible sur kBgCard', () {
        expect(contrast(entry.value, kBgCard), greaterThanOrEqualTo(3.0));
      });
    }

    test('kGoldDeep permet du texte blanc, pas kGold', () {
      // kGold ne fait que 2,15:1 avec du blanc : il ne doit servir que de
      // remplissage ou d'accent, jamais de fond pour du texte blanc.
      expect(contrast(Colors.white, kGold), lessThan(4.5));
      expect(contrast(Colors.white, kGoldDeep), greaterThanOrEqualTo(4.5));
    });
  });

  test('la hiérarchie visuelle est préservée', () {
    // Plus le texte est secondaire, plus il doit être discret — sans jamais
    // descendre sous AA.
    expect(contrast(kTextPrim, kBg), greaterThan(contrast(kTextSub, kBg)));
    expect(contrast(kTextSub, kBg), greaterThan(contrast(kTextLight, kBg)));
  });
}

String _hex(Color c) =>
    '#${((c.a * 255).round() << 24 | (c.r * 255).round() << 16 | (c.g * 255).round() << 8 | (c.b * 255).round()).toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
