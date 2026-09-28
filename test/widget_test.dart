import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planify/utils/validators.dart';
import 'package:planify/widgets/password_strength_indicator.dart';

void main() {
  group('Validators', () {
    test('email', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('  a.b@exemple.tg '), isNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
      expect(Validators.email('a b@c.com'), isNotNull);
    });

    test('mot de passe : 8 caractères, 1 majuscule, 1 chiffre', () {
      expect(Validators.isStrongPassword('Abcdefg1'), isTrue);
      expect(Validators.isStrongPassword('abcdefg1'), isFalse);
      expect(Validators.isStrongPassword('Abcdefgh'), isFalse);
      expect(Validators.isStrongPassword('Abc1'), isFalse);
    });

    test('force du mot de passe', () {
      expect(PasswordStrength.of(''), PasswordStrength.vide);
      expect(PasswordStrength.of('abc'), PasswordStrength.faible);
      expect(PasswordStrength.of('Abcdefg1'), PasswordStrength.moyen);
      expect(PasswordStrength.of('Abcdefgh1234'), PasswordStrength.bon);
      expect(PasswordStrength.of('Abcdefgh1234!'), PasswordStrength.fort);
    });
  });

  testWidgets("l'indicateur affiche le niveau de force", (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PasswordStrengthIndicator(password: 'Abcdefgh1234!')),
    ));
    expect(find.text('Force : Fort'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PasswordStrengthIndicator(password: '')),
    ));
    expect(find.textContaining('Force'), findsNothing);
  });
}
