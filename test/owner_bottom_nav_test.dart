import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:mini_foot_owner_flutter/core/widgets/lazy_indexed_stack.dart';
import 'package:mini_foot_owner_flutter/core/widgets/owner_bottom_nav.dart';

const _destinations = [
  OwnerNavDestination(icon: PhosphorIconsRegular.squaresFour, label: 'Accueil'),
  OwnerNavDestination(icon: PhosphorIconsRegular.courtBasketball, label: 'Terrains'),
  OwnerNavDestination(icon: PhosphorIconsRegular.qrCode, label: 'Scanner'),
  OwnerNavDestination(icon: PhosphorIconsRegular.wallet, label: 'Paiements'),
  OwnerNavDestination(icon: PhosphorIconsRegular.user, label: 'Profil'),
];

void main() {
  group('OwnerBottomNav', () {
    Widget wrap({required int current, required ValueChanged<int> onSelected}) =>
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: OwnerBottomNav(
              destinations: _destinations,
              currentIndex: current,
              centerIndex: 2,
              centerLabel: 'Scanner un QR code de réservation',
              onSelected: onSelected,
            ),
          ),
        );

    testWidgets('rend un libellé par destination sauf le bouton central', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(current: 0, onSelected: (_) {}));

      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Terrains'), findsOneWidget);
      expect(find.text('Paiements'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
      // Le bouton central est une image, son libellé n'est que sémantique.
      expect(find.text('Scanner'), findsNothing);
    });

    testWidgets('notifie la destination touchée', (tester) async {
      final taps = <int>[];
      await tester.pumpWidget(wrap(current: 0, onSelected: taps.add));

      await tester.tap(find.text('Paiements'));
      await tester.pump();
      expect(taps, [3]);
    });

    testWidgets('le bouton central, sans texte, porte un libellé sémantique', (
      tester,
    ) async {
      // Sans cela, un lecteur d'écran n'annonce rien sur l'action la plus
      // utilisée de l'app.
      await tester.pumpWidget(wrap(current: 0, onSelected: (_) {}));

      expect(
        find.bySemanticsLabel('Scanner un QR code de réservation'),
        findsOneWidget,
      );
    });

    testWidgets('les libellés ne débordent pas sur un écran de 320 pt', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(current: 0, onSelected: (_) {}));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('LazyIndexedStack', () {
    testWidgets('ne construit que l’onglet visité', (tester) async {
      // Un IndexedStack ordinaire construit tous ses enfants : la coquille
      // déclencherait cinq chargements réseau au démarrage.
      final built = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: LazyIndexedStack(
            index: 0,
            itemCount: 3,
            itemBuilder: (_, i) {
              built.add(i);
              return Text('onglet $i');
            },
          ),
        ),
      );

      expect(built, [0]);
    });

    testWidgets('garde les onglets déjà visités montés', (tester) async {
      final built = <int>[];

      Widget shell(int index) => MaterialApp(
        home: LazyIndexedStack(
          index: index,
          itemCount: 3,
          itemBuilder: (_, i) {
            built.add(i);
            return Text('onglet $i');
          },
        ),
      );

      await tester.pumpWidget(shell(0));
      await tester.pumpWidget(shell(2));

      // 0 reste monté (c'est l'intérêt : défilement et filtres conservés),
      // 1 n'a jamais été visité.
      expect(built.toSet(), {0, 2});
    });
  });
}
