import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Hachage des secrets (mots de passe, réponses secrètes) par
/// PBKDF2-HMAC-SHA256 avec un sel aléatoire propre à chaque valeur.
///
/// Format stocké : `pbkdf2_sha256$<itérations>$<sel base64>$<hash base64>`.
/// Le nombre d'itérations est enregistré avec le hash, ce qui permet de
/// l'augmenter plus tard sans invalider les comptes existants.
class PasswordHasher {
  static const String _prefix = 'pbkdf2_sha256';
  static const int _iterations = 20000;
  static const int _saltLength = 16;
  static const int _keyLength = 32;

  /// Indique si la valeur stockée est déjà un hash (et non un ancien mot de
  /// passe en clair datant d'avant la migration v6).
  static bool isHashed(String stored) => stored.startsWith('$_prefix\$');

  static Future<String> hash(String secret) {
    final salt = _randomSalt();
    return compute(_hashIsolate, _HashArgs(secret, salt, _iterations));
  }

  static Future<bool> verify(String secret, String stored) async {
    final parts = stored.split('\$');
    if (parts.length != 4 || parts[0] != _prefix) return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null) return false;
    final salt = base64Decode(parts[2]);
    final expected = parts[3];
    final actual = await compute(
        _hashIsolate, _HashArgs(secret, salt, iterations));
    return _constantTimeEquals(actual.split('\$')[3], expected);
  }

  static Uint8List _randomSalt() {
    final rnd = Random.secure();
    return Uint8List.fromList(
        List<int>.generate(_saltLength, (_) => rnd.nextInt(256)));
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

class _HashArgs {
  final String secret;
  final Uint8List salt;
  final int iterations;
  const _HashArgs(this.secret, this.salt, this.iterations);
}

String _hashIsolate(_HashArgs args) {
  final key = pbkdf2Sha256(
    utf8.encode(args.secret),
    args.salt,
    args.iterations,
    PasswordHasher._keyLength,
  );
  return '${PasswordHasher._prefix}\$${args.iterations}'
      '\$${base64Encode(args.salt)}\$${base64Encode(key)}';
}

/// PBKDF2 (RFC 8018) avec HMAC-SHA256.
@visibleForTesting
Uint8List pbkdf2Sha256(
    List<int> password, List<int> salt, int iterations, int keyLength) {
  final hmac = Hmac(sha256, password);
  final blocks = (keyLength / 32).ceil();
  final out = BytesBuilder();
  for (var block = 1; block <= blocks; block++) {
    final blockIndex = [
      (block >> 24) & 0xff,
      (block >> 16) & 0xff,
      (block >> 8) & 0xff,
      block & 0xff,
    ];
    var u = hmac.convert([...salt, ...blockIndex]).bytes;
    final t = Uint8List.fromList(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    out.add(t);
  }
  return Uint8List.fromList(out.toBytes().sublist(0, keyLength));
}
