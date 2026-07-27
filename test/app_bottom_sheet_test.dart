import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mini_foot_owner_flutter/core/theme/app_theme.dart';
import 'package:mini_foot_owner_flutter/core/widgets/app_bottom_sheet.dart';
import 'package:mini_foot_owner_flutter/core/widgets/app_text_field.dart';

/// Contenu de feuille qui possède son propre `TextEditingController`.
///
/// C'est le motif correct : le widget qui crée le contrôleur le libère dans son
/// `dispose()`, donc **après** l'animation de fermeture. Libérer juste après
/// `await Get.bottomSheet(...)` est trop tôt — la feuille est encore à l'écran
/// et lève « A TextEditingController was used after being disposed ».
class _OwningSheet extends StatefulWidget {
  const _OwningSheet();

  @override
  State<_OwningSheet> createState() => _OwningSheetState();
}

class _OwningSheetState extends State<_OwningSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppTextField(
    controller: _ctrl,
    label: 'Prénom',
  );
}

void main() {
  testWidgets('la feuille se ferme sans utiliser un contrôleur libéré', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  AppBottomSheet.show<void>(child: const _OwningSheet()),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    expect(find.byType(AppTextField), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Moussa');
    await tester.pump();

    Get.back();
    // `pumpAndSettle` déroule toute l'animation de fermeture : c'est pendant
    // celle-ci que la libération prématurée se manifestait.
    await tester.pumpAndSettle();

    expect(find.byType(AppTextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ouvrir deux fois de suite ne duplique pas de GlobalKey', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: appTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  AppBottomSheet.show<void>(child: const _OwningSheet()),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      Get.back();
      await tester.pumpAndSettle();
    }

    expect(tester.takeException(), isNull);
  });
}
