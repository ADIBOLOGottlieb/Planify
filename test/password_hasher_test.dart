import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:planify/utils/password_hasher.dart';

void main() {
  test('PBKDF2-HMAC-SHA256 respecte le vecteur de test RFC 7914', () {
    // RFC 7914 §11 : P="passwd", S="salt", c=1, dkLen=64
    final key = pbkdf2Sha256(utf8.encode('passwd'), utf8.encode('salt'), 1, 64);
    expect(
      key.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc'
      '49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783',
    );
  });

  test('hash puis verify', () async {
    final sw = Stopwatch()..start();
    final h = await PasswordHasher.hash('MotDePasse1');
    // ignore: avoid_print
    print('hash en ${sw.elapsedMilliseconds} ms');
    expect(PasswordHasher.isHashed(h), isTrue);
    expect(h, isNot(contains('MotDePasse1')));
    expect(await PasswordHasher.verify('MotDePasse1', h), isTrue);
    expect(await PasswordHasher.verify('motdepasse1', h), isFalse);
  });

  test('deux hash du même mot de passe diffèrent (sel aléatoire)', () async {
    expect(await PasswordHasher.hash('abc'), isNot(await PasswordHasher.hash('abc')));
  });

  test('un mot de passe en clair n\'est pas reconnu comme hash', () {
    expect(PasswordHasher.isHashed('MotDePasse1'), isFalse);
  });
}
