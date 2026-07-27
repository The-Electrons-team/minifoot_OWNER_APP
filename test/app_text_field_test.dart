import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mini_foot_owner_flutter/core/utils/app_validators.dart';
import 'package:mini_foot_owner_flutter/core/widgets/app_text_field.dart';

void main() {
  setUp(() => dotenv.testLoad(fileInput: ''));

  Widget wrap(Widget child, {GlobalKey<FormState>? formKey}) => MaterialApp(
    home: Scaffold(
      body: Form(key: formKey, child: child),
    ),
  );

  testWidgets('affiche l’erreur sous le champ, pas dans un toast', (
    tester,
  ) async {
    // C'est tout l'objet du lot : l'app n'avait aucun `Form`, et chaque erreur
    // de saisie partait en snackbar en haut de l'écran — sans dire quel champ
    // corriger sur un formulaire de plusieurs pages.
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      wrap(
        AppTextField(
          label: 'Téléphone',
          validator: AppValidators.phone,
        ),
        formKey: formKey,
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Numéro requis'), findsOneWidget);
  });

  testWidgets('valide dès la saisie, sans attendre la soumission', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(AppTextField(label: 'Téléphone', validator: AppValidators.phone)),
    );

    await tester.enterText(find.byType(TextFormField), '12');
    await tester.pump();
    expect(find.textContaining('Numéro invalide'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '771272788');
    await tester.pump();
    expect(find.textContaining('Numéro invalide'), findsNothing);
  });

  testWidgets('un champ valide ne montre aucune erreur', (tester) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController(text: '771272788');
    addTearDown(ctrl.dispose);

    await tester.pumpWidget(
      wrap(
        AppTextField(controller: ctrl, validator: AppValidators.phone),
        formKey: formKey,
      ),
    );

    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('le libellé est rendu au-dessus du champ', (tester) async {
    await tester.pumpWidget(wrap(const AppTextField(label: 'Prénom')));
    expect(find.text('Prénom'), findsOneWidget);
  });

  testWidgets('transmet les indices de remplissage automatique', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const AppTextField(
          autofillHints: [AutofillHints.oneTimeCode],
        ),
      ),
    );

    // `TextFormField` n'expose pas ses options : on inspecte l'`EditableText`
    // qu'il construit, c'est lui qui parle au système.
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.autofillHints, contains(AutofillHints.oneTimeCode));
  });
}
