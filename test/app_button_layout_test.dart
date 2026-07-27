import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foot_owner_flutter/core/theme/app_theme.dart';
import 'package:mini_foot_owner_flutter/core/widgets/app_button.dart';

/// Le thème posait `minimumSize: Size.fromHeight(54)`, qui vaut
/// `Size(double.infinity, 54)` : tout bouton exigeait une largeur infinie et
/// faisait planter la mise en page dans un contexte non borné en largeur —
/// une `Row`, typiquement. Le dialogue de confirmation en était la victime.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: appTheme,
    home: Scaffold(body: child),
  );

  testWidgets('un bouton tient dans une Row sans exiger de largeur infinie', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () {}, child: const Text('Annuler')),
            ElevatedButton(onPressed: () {}, child: const Text('Supprimer')),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('AppButton non étendu tient dans une Row', (tester) async {
    await tester.pumpWidget(
      wrap(
        Row(
          children: [
            AppButton(label: 'Réessayer', onPressed: () {}, expanded: false),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('AppButton étendu occupe toute la largeur', (tester) async {
    await tester.pumpWidget(
      wrap(AppButton(label: 'Enregistrer', onPressed: () {})),
    );

    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byType(ElevatedButton));
    expect(size.height, AppTouch.buttonHeight);
    expect(size.width, 800); // largeur de l'écran de test
  });

  testWidgets('la hauteur minimale reste appliquée', (tester) async {
    await tester.pumpWidget(
      wrap(
        Row(children: [ElevatedButton(onPressed: () {}, child: const Text('X'))]),
      ),
    );

    expect(
      tester.getSize(find.byType(ElevatedButton)).height,
      greaterThanOrEqualTo(AppTouch.buttonHeight),
    );
  });
}
