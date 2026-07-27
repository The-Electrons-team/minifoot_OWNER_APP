import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foot_owner_flutter/core/widgets/app_states.dart';
import 'package:mini_foot_owner_flutter/core/widgets/async_view.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  const content = Text('contenu');

  group('AsyncView', () {
    testWidgets('affiche les données quand tout va bien', (tester) async {
      await tester.pumpWidget(
        _wrap(const AsyncView(isLoading: false, child: content)),
      );
      expect(find.text('contenu'), findsOneWidget);
      expect(find.byType(AppErrorState), findsNothing);
      expect(find.byType(AppEmptyState), findsNothing);
    });

    testWidgets('affiche l’état vide', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AsyncView(
            isLoading: false,
            isEmpty: true,
            emptyTitle: 'Aucun terrain',
            child: content,
          ),
        ),
      );
      expect(find.text('Aucun terrain'), findsOneWidget);
      expect(find.text('contenu'), findsNothing);
    });

    testWidgets('l’erreur prime sur le vide', (tester) async {
      // C'est le cœur du problème corrigé : une liste vide *parce que* la
      // requête a échoué ne doit jamais s'afficher comme « vous n'avez rien ».
      await tester.pumpWidget(
        _wrap(
          AsyncView(
            isLoading: false,
            isEmpty: true,
            error: 'Pas de connexion',
            emptyTitle: 'Aucun terrain',
            onRetry: () {},
            child: content,
          ),
        ),
      );
      expect(find.text('Pas de connexion'), findsOneWidget);
      expect(find.text('Aucun terrain'), findsNothing);
    });

    testWidgets('le chargement prime sur tout le reste', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AsyncView(
            isLoading: true,
            isEmpty: true,
            error: 'Pas de connexion',
            child: content,
          ),
        ),
      );
      expect(find.text('Pas de connexion'), findsNothing);
      expect(find.byType(AppEmptyState), findsNothing);
    });
  });

  group('AppErrorState', () {
    testWidgets('propose Réessayer et déclenche le rappel', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        _wrap(
          AppErrorState(message: 'Échec', onRetry: () => retried++),
        ),
      );

      expect(find.text('Réessayer'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      await tester.pump();
      expect(retried, 1);
    });

    testWidgets('sans rappel, aucun bouton', (tester) async {
      await tester.pumpWidget(_wrap(const AppErrorState(message: 'Échec')));
      expect(find.text('Réessayer'), findsNothing);
    });
  });

  group('AppEmptyState', () {
    testWidgets('affiche une action quand elle est fournie', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          AppEmptyState(
            title: 'Aucun contrôleur',
            message: 'Ajoutez une personne de confiance.',
            actionLabel: 'Ajouter',
            onAction: () => tapped++,
          ),
        ),
      );

      expect(find.text('Aucun contrôleur'), findsOneWidget);
      await tester.tap(find.text('Ajouter'));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('sans action, pas de bouton', (tester) async {
      await tester.pumpWidget(
        _wrap(const AppEmptyState(title: 'Vide', actionLabel: 'Ajouter')),
      );
      // actionLabel seul ne suffit pas : il faut aussi un rappel.
      expect(find.text('Ajouter'), findsNothing);
    });
  });
}
