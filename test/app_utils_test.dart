import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_foot_owner_flutter/core/utils/app_async.dart';
import 'package:mini_foot_owner_flutter/core/utils/app_motion.dart';
import 'package:mini_foot_owner_flutter/core/utils/app_phone.dart';
import 'package:mini_foot_owner_flutter/core/utils/app_validators.dart';

void main() {
  setUp(() => dotenv.testLoad(fileInput: ''));

  group('AppPhone.normalize', () {
    test('accepte le format proposé en exemple par le champ de retrait', () {
      // Le hint affichait « +221 77 000 00 00 » alors que la validation
      // rejetait les espaces : le retrait devenait impossible.
      expect(AppPhone.normalize('+221 77 000 00 00'), '+221770000000');
    });

    test('accepte les variantes courantes', () {
      const expected = '+221771272788';
      expect(AppPhone.normalize('+221771272788'), expected);
      expect(AppPhone.normalize('221771272788'), expected);
      expect(AppPhone.normalize('00221771272788'), expected);
      expect(AppPhone.normalize('0771272788'), expected);
      expect(AppPhone.normalize('771272788'), expected);
      expect(AppPhone.normalize('77 127 27 88'), expected);
      expect(AppPhone.normalize('+221-77-127-27-88'), expected);
    });

    test('rejette ce qui n’est pas exploitable', () {
      expect(AppPhone.normalize(null), isNull);
      expect(AppPhone.normalize(''), isNull);
      expect(AppPhone.normalize('12'), isNull);
      expect(AppPhone.normalize('7712727881234'), isNull);
      expect(AppPhone.normalize('abc'), isNull);
    });

    test('format produit un numéro lisible', () {
      expect(AppPhone.format('771272788'), '+221 77 127 27 88');
    });

    test('format laisse passer une valeur non normalisable', () {
      expect(AppPhone.format('inconnu'), 'inconnu');
    });
  });

  group('AppValidators.password', () {
    test('applique la même longueur minimale partout', () {
      // Elle valait 8 à l'inscription et 6 au reset : un compte créé à 8
      // pouvait être ramené à 6.
      expect(AppValidators.minPasswordLength, 8);
      expect(AppValidators.password('1234567'), isNotNull);
      expect(AppValidators.password('12345678'), isNull);
      expect(AppValidators.password(''), 'Mot de passe requis');
      expect(AppValidators.password(null), 'Mot de passe requis');
    });

    test('confirmation', () {
      expect(AppValidators.passwordConfirmation('abc', 'abc'), isNull);
      expect(AppValidators.passwordConfirmation('abc', 'abd'), isNotNull);
      expect(AppValidators.passwordConfirmation('', 'abc'), isNotNull);
    });

    test('téléphone et champ requis', () {
      expect(AppValidators.phone('771272788'), isNull);
      expect(AppValidators.phone('12'), isNotNull);
      expect(AppValidators.required('  '), isNotNull);
      expect(AppValidators.required('x'), isNull);
    });

    test('otp', () {
      expect(AppValidators.otp('123456'), isNull);
      expect(AppValidators.otp('123'), isNotNull);
      expect(AppValidators.otp(''), 'Code requis');
    });
  });

  group('AppMotion.stagger', () {
    test('croît puis se stabilise', () {
      expect(AppMotion.stagger(0), Duration.zero);
      expect(AppMotion.stagger(3), const Duration(milliseconds: 240));
    });

    test('borne le délai — le 50e élément n’attend plus 4 secondes', () {
      final last = AppMotion.stagger(50);
      expect(last, AppMotion.stagger(AppMotion.maxStaggeredItems));
      expect(last.inMilliseconds, lessThanOrEqualTo(800));
    });

    test('respecte base et step', () {
      expect(
        AppMotion.stagger(2, step: 60, base: 400),
        const Duration(milliseconds: 520),
      );
    });
  });

  group('AppAsync.mapBounded', () {
    test('préserve l’ordre des résultats', () async {
      final result = await AppAsync.mapBounded<int, int>(
        List.generate(20, (i) => i),
        (i) async => i * 2,
        concurrency: 3,
      );
      expect(result, List.generate(20, (i) => i * 2));
    });

    test('borne réellement la concurrence', () async {
      var running = 0;
      var peak = 0;

      await AppAsync.mapBounded<int, void>(
        List.generate(30, (i) => i),
        (_) async {
          running++;
          if (running > peak) peak = running;
          await Future<void>.delayed(Duration.zero);
          running--;
        },
        concurrency: 4,
      );

      expect(peak, lessThanOrEqualTo(4));
      expect(peak, greaterThan(1)); // sinon on serait resté séquentiel
    });

    test('liste vide', () async {
      expect(await AppAsync.mapBounded<int, int>([], (i) async => i), isEmpty);
    });
  });
}
