/// Échelles de valeurs du design system.
///
/// Le projet documentait 7 rayons et 5 espacements ; le code en utilisait 20 et
/// 23, parce que rien ne les nommait. Une valeur qui a un nom se réutilise, une
/// valeur littérale se réinvente.
///
/// N'ajoutez un palier que si aucun existant ne convient — c'est ainsi que les
/// échelles restent courtes.
library;

import 'package:flutter/widgets.dart';

/// Espacements. Multiples de 4, comme la grille Material.
class AppSpacing {
  const AppSpacing._();

  /// 4 — écart entre une icône et son libellé.
  static const double xxs = 4;

  /// 8 — entre éléments d'une même ligne.
  static const double xs = 8;

  /// 12 — padding interne des petits conteneurs.
  static const double sm = 12;

  /// 16 — padding interne des cartes.
  static const double md = 16;

  /// 20 — marge horizontale des pages.
  static const double lg = 20;

  /// 24 — entre une section et le bouton principal.
  static const double xl = 24;

  /// 36 — bas de page des écrans internes.
  static const double xxl = 36;

  /// Marge horizontale standard d'une page.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: lg);

  /// Padding interne d'une carte.
  static const EdgeInsets card = EdgeInsets.all(md);
}

/// Rayons de bordure.
class AppRadius {
  const AppRadius._();

  /// 12 — badges, chips, conteneurs d'icônes.
  static const double xs = 12;

  /// 14 — champs de saisie.
  static const double sm = 14;

  /// 18 — cartes et boutons principaux.
  static const double md = 18;

  /// 24 — bottom sheets.
  static const double lg = 24;

  /// 36 — barre de navigation en pilule.
  static const double pill = 36;

  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);

  /// Coins supérieurs arrondis, pour les feuilles modales.
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
}

/// Tailles typographiques.
///
/// Le minimum est 11 : en dessous, le texte devient illisible en extérieur —
/// et l'app s'utilise au bord du terrain, en plein soleil.
class AppFontSize {
  const AppFontSize._();

  /// 11 — libellés de navigation, badges. Plancher absolu.
  static const double caption = 11;

  /// 12 — libellés de cartes.
  static const double label = 12;

  /// 13 — corps de texte dense.
  static const double bodySmall = 13;

  /// 14 — corps de texte courant.
  static const double body = 14;

  /// 16 — texte mis en avant.
  static const double bodyLarge = 16;

  /// 18 — titres d'AppBar.
  static const double title = 18;

  /// 22 — valeurs chiffrées importantes.
  static const double display = 22;
}

/// Tailles des conteneurs d'icônes et de leur icône.
class AppIconBox {
  const AppIconBox._();

  /// 36 × 36, icône 18 — mini-cartes, champs de formulaire.
  static const double sm = 36;
  static const double smIcon = 18;

  /// 40 × 40, icône 20 — actions rapides.
  static const double md = 40;
  static const double mdIcon = 22;

  /// 46 × 46, icône 22 — tuiles de réservation et de notification.
  static const double lg = 46;
  static const double lgIcon = 22;
}

/// Dimensions des zones interactives.
class AppTouch {
  const AppTouch._();

  /// Cible tactile minimale recommandée (Material et HIG s'accordent sur 48).
  static const double minTarget = 48;

  /// Hauteur d'un bouton principal.
  static const double buttonHeight = 54;
}
