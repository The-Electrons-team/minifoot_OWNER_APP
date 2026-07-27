import 'package:intl/intl.dart';

/// Formatage des montants et des dates.
///
/// Sept implémentations maison coexistaient — chacune avec sa boucle de
/// séparateur de milliers — et deux d'entre elles **ne donnaient pas le même
/// résultat** pour le même montant : le solde affiché sur le tableau de bord
/// pouvait différer de celui de l'écran Paiements.
///
/// Les suffixes divergeaient aussi (`F`, `F CFA`, `F/h`). Ici, une seule règle.
class AppFormat {
  const AppFormat._();

  static const String currencySymbol = 'F CFA';
  static const String _locale = 'fr_FR';

  static final NumberFormat _decimal = NumberFormat.decimalPattern(_locale);

  /// Montant complet : `10 000 F CFA`.
  ///
  /// Le séparateur est l'espace insécable fine du français, appliqué par `intl`
  /// — les boucles maison utilisaient une espace ordinaire, qui autorise un
  /// retour à la ligne au milieu d'un nombre.
  static String amount(num value, {bool withSymbol = true}) {
    final formatted = _decimal.format(value);
    return withSymbol ? '$formatted $currencySymbol' : formatted;
  }

  /// Montant abrégé pour les axes de graphique et les badges : `1,2 M`, `450 k`.
  ///
  /// Au-delà du million on garde une décimale, sinon la valeur perd son sens ;
  /// en dessous du millier on n'abrège pas.
  static String amountCompact(num value, {bool withSymbol = false}) {
    final abs = value.abs();
    String core;

    if (abs >= 1000000) {
      core = '${_trim(value / 1000000)} M';
    } else if (abs >= 1000) {
      core = '${_trim(value / 1000)} k';
    } else {
      core = _decimal.format(value);
    }

    return withSymbol ? '$core $currencySymbol' : core;
  }

  /// Tarif horaire : `15 000 F/h`.
  static String pricePerHour(num value) => '${_decimal.format(value)} F/h';

  /// Une décimale, et seulement si elle apporte quelque chose.
  static String _trim(double value) {
    final rounded = (value * 10).round() / 10;
    if (rounded == rounded.roundToDouble()) return rounded.toStringAsFixed(0);
    return rounded.toStringAsFixed(1).replaceAll('.', ',');
  }

  // ── Dates ─────────────────────────────────────────────────────────────────
  // Toujours avec la locale : deux appels l'omettaient et retombaient sur la
  // locale système, produisant des dates en anglais sur un téléphone anglophone.

  static final DateFormat _day = DateFormat('d MMM yyyy', _locale);
  static final DateFormat _dayTime = DateFormat('d MMM yyyy • HH:mm', _locale);
  static final DateFormat _shortDayTime = DateFormat('dd/MM HH:mm', _locale);
  static final DateFormat _month = DateFormat('MMMM yyyy', _locale);
  static final DateFormat _numeric = DateFormat('dd/MM/yyyy', _locale);

  /// `15 août 2026`
  static String date(DateTime value) => _day.format(value);

  /// `15 août 2026 • 18:00`
  static String dateTime(DateTime value) => _dayTime.format(value);

  /// `15/08 18:00`
  static String shortDateTime(DateTime value) => _shortDayTime.format(value);

  /// `août 2026`
  static String month(DateTime value) => _month.format(value);

  /// `15/08/2026`
  static String numericDate(DateTime value) => _numeric.format(value);
}
