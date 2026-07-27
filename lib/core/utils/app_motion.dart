import 'dart:math' as math;

/// Constantes de mouvement partagées.
class AppMotion {
  const AppMotion._();

  /// Rang au-delà duquel la cascade cesse de s'allonger.
  static const int maxStaggeredItems = 8;

  /// Délai d'apparition en cascade, **borné**.
  ///
  /// Sans borne (`index * 80`), le 50ᵉ élément d'une liste attend 4 secondes :
  /// l'animation cesse d'être un habillage et devient de la latence perçue.
  /// Au-delà de [maxStaggeredItems], tous les éléments apparaissent ensemble —
  /// de toute façon ils sont hors écran.
  static Duration stagger(int index, {int step = 80, int base = 0}) => Duration(
    milliseconds: base + math.min(index, maxStaggeredItems) * step,
  );
}
