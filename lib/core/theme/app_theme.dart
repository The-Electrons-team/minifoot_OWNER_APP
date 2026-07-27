import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';

// Les tokens sont réexportés : importer `app_theme.dart` suffit pour disposer
// de la palette, des espacements et des rayons.
export 'app_tokens.dart';

// ─── Palette harmonisée avec l'app client ───────────────────────────────────
const Color kBg        = Color(0xFFF5F0E8);   // fond beige chaud (identique client)
const Color kBgCard    = Color(0xFFFFFFFF);   // cartes blanches
const Color kBgSurface = Color(0xFFF0EBE3);   // surface inputs (beige plus clair)
const Color kGreen     = Color(0xFF006F39);   // vert principal (identique client)
const Color kGreenDark = Color(0xFF00C264);   // vert clair pour dark mode/accents
const Color kGreenDim  = Color(0xFF005A2E);   // vert foncé
const Color kGreenLight= Color(0xFFE8F5E9);   // vert très clair (badges, fonds)
const Color kGold      = Color(0xFFF59E0B);   // or/revenus
const Color kGoldLight = Color(0xFFFEF3C7);   // or clair (badge fond)
const Color kRed       = Color(0xFFEF4444);   // danger
const Color kRedLight  = Color(0xFFFEE2E2);   // danger clair (badge fond)
const Color kBlue      = Color(0xFF1565C0);   // info (identique client)
const Color kBlueLight = Color(0xFFDBEAFE);   // info clair
const Color kOrange    = Color(0xFFE65100);   // orange accent
const Color kTextPrim  = Color(0xFF1A1A1A);   // texte principal — 15,3:1 sur kBg
// Les deux niveaux secondaires ont été assombris pour passer WCAG AA (4,5:1)
// sur kBg comme sur kBgSurface. Les valeurs d'origine (#6B7280 et #9CA3AF)
// tombaient à 4,26:1 et 2,24:1 : illisibles au soleil, et #9CA3AF servait de
// couleur par défaut à *tous* les placeholders. Voir test/theme_contrast_test.dart.
const Color kTextSub   = Color(0xFF4B5563);   // texte secondaire — 6,66:1 sur kBg
const Color kTextLight = Color(0xFF5F6672);   // texte léger, placeholders — 5,10:1
// Or lisible en texte sur fond clair : kGold (#F59E0B) ne fait que 2,15:1 avec
// du blanc, il ne doit servir que de remplissage ou d'accent.
const Color kGoldDeep  = Color(0xFFB45309);   // 5,02:1 avec du blanc
const Color kBorder    = Color(0xFFE5E0D8);   // bordures beige
const Color kDivider   = Color(0xFFF0EBE3);   // séparateurs

// ─── Couleurs de marque des moyens de paiement ──────────────────────────────
// Imposées par les opérateurs : elles ne suivent pas la palette et ne doivent
// pas être « harmonisées ». Nommées ici pour cesser d'être recopiées à la main.
const Color kBrandWave        = Color(0xFF00B0F0);
const Color kBrandOrangeMoney = Color(0xFFFF6D00);
const Color kBrandYasMoney    = Color(0xFFFFD100);

// ─── Ombres (style client) ──────────────────────────────────────────────────
List<BoxShadow> get kCardShadow => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    blurRadius: 12,
    offset: const Offset(0, 4),
  ),
];

List<BoxShadow> get kElevatedShadow => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.12),
    blurRadius: 20,
    offset: const Offset(0, 6),
  ),
];

List<BoxShadow> get kNavShadow => [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.10),
    blurRadius: 20,
    offset: const Offset(0, 4),
  ),
];

// ─── Gradients ──────────────────────────────────────────────────────────────
const LinearGradient kGreenGradient = LinearGradient(
  colors: [Color(0xFF006F39), Color(0xFF00C264)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient kGoldGradient = LinearGradient(
  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// ─── ThemeData ──────────────────────────────────────────────────────────────
// Tout ce qui est stylable par le thème doit l'être ici. Chaque composant qui
// manque à cette liste finit réécrit à la main dans les écrans — c'est ainsi
// qu'on en est arrivé à 302 `BoxDecoration` et 250 couleurs en dur.
ThemeData get appTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: kBg,
  cardColor: kBgCard,
  colorScheme: const ColorScheme.light(
    primary: kGreen,
    onPrimary: Colors.white,
    primaryContainer: kGreenLight,
    onPrimaryContainer: kGreenDim,
    secondary: kGold,
    onSecondary: kTextPrim,
    secondaryContainer: kGoldLight,
    onSecondaryContainer: kGoldDeep,
    tertiary: kBlue,
    tertiaryContainer: kBlueLight,
    surface: kBgCard,
    onSurface: kTextPrim,
    surfaceContainerHighest: kBgSurface,
    onSurfaceVariant: kTextSub,
    error: kRed,
    onError: Colors.white,
    errorContainer: kRedLight,
    outline: kBorder,
    outlineVariant: kDivider,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    iconTheme: IconThemeData(color: kTextPrim),
    titleTextStyle: TextStyle(
      fontFamily: 'Orbitron',
      color: kTextPrim,
      fontSize: AppFontSize.title,
      fontWeight: FontWeight.w700,
    ),
  ),

  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'Orbitron',
      color: kTextPrim,
      fontWeight: FontWeight.w900,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Orbitron',
      color: kTextPrim,
      fontWeight: FontWeight.w800,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Orbitron',
      color: kTextPrim,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: TextStyle(
      color: kTextPrim,
      fontSize: AppFontSize.bodyLarge,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      color: kTextSub,
      fontSize: AppFontSize.body,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      color: kTextLight,
      fontSize: AppFontSize.label,
      height: 1.5,
    ),
    labelLarge: TextStyle(
      color: kTextPrim,
      fontSize: AppFontSize.body,
      fontWeight: FontWeight.w600,
    ),
  ),

  cardTheme: CardThemeData(
    color: kBgCard,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kBgCard,
    hintStyle: const TextStyle(color: kTextLight, fontSize: AppFontSize.body),
    labelStyle: const TextStyle(color: kTextSub, fontSize: AppFontSize.body),
    errorStyle: const TextStyle(color: kRed, fontSize: AppFontSize.caption),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: AppRadius.smAll,
      borderSide: const BorderSide(color: kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppRadius.smAll,
      borderSide: const BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadius.smAll,
      borderSide: const BorderSide(color: kGreen, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppRadius.smAll,
      borderSide: const BorderSide(color: kRed),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: AppRadius.smAll,
      borderSide: const BorderSide(color: kRed, width: 1.5),
    ),
  ),

  // Rayon 18 : c'est la valeur du design system documenté. Le thème disait 14,
  // les écrans redessinaient donc leurs boutons à la main.
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kGreen,
      foregroundColor: Colors.white,
      disabledBackgroundColor: kGreen.withValues(alpha: 0.5),
      disabledForegroundColor: Colors.white,
      elevation: 0,
      // `Size(0, h)` et non `Size.fromHeight(h)` : ce dernier vaut
      // `Size(double.infinity, h)` et force une largeur infinie, ce qui fait
      // planter la mise en page dès qu'un bouton est placé dans une Row.
      // Ici on impose une hauteur minimale, la largeur reste libre.
      minimumSize: const Size(0, AppTouch.buttonHeight),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 15,
        letterSpacing: 0.3,
      ),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kTextPrim,
      // `Size(0, h)` et non `Size.fromHeight(h)` : ce dernier vaut
      // `Size(double.infinity, h)` et force une largeur infinie, ce qui fait
      // planter la mise en page dès qu'un bouton est placé dans une Row.
      // Ici on impose une hauteur minimale, la largeur reste libre.
      minimumSize: const Size(0, AppTouch.buttonHeight),
      padding: const EdgeInsets.symmetric(vertical: 14),
      side: const BorderSide(color: kBorder),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: kGreen,
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
  ),

  dialogTheme: DialogThemeData(
    backgroundColor: kBgCard,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
    titleTextStyle: const TextStyle(
      fontFamily: 'Orbitron',
      color: kTextPrim,
      fontSize: 17,
      fontWeight: FontWeight.w700,
    ),
    contentTextStyle: const TextStyle(
      color: kTextSub,
      fontSize: AppFontSize.body,
      height: 1.5,
    ),
  ),

  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: kBgCard,
    elevation: 0,
    modalElevation: 0,
    showDragHandle: true,
    dragHandleColor: kBorder,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.sheet),
  ),

  chipTheme: ChipThemeData(
    backgroundColor: kBgSurface,
    selectedColor: kGreen,
    side: const BorderSide(color: kBorder),
    shape: RoundedRectangleBorder(borderRadius: AppRadius.xsAll),
    labelStyle: const TextStyle(
      color: kTextSub,
      fontSize: AppFontSize.bodySmall,
      fontWeight: FontWeight.w600,
    ),
    secondaryLabelStyle: const TextStyle(
      color: Colors.white,
      fontSize: AppFontSize.bodySmall,
      fontWeight: FontWeight.w600,
    ),
  ),

  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: kTextPrim,
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontSize: AppFontSize.bodySmall,
    ),
    shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
  ),

  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: kGreen,
    linearTrackColor: kDivider,
    circularTrackColor: kDivider,
  ),

  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected) ? Colors.white : kBgCard,
    ),
    trackColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected) ? kGreen : kBorder,
    ),
  ),

  listTileTheme: const ListTileThemeData(
    iconColor: kTextSub,
    textColor: kTextPrim,
  ),

  dividerColor: kDivider,
  dividerTheme: const DividerThemeData(color: kDivider, thickness: 1),
);
