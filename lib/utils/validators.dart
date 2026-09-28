import 'package:flutter/material.dart';

class Validators {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? email(String? v) {
    if (v == null || !_email.hasMatch(v.trim())) return 'Email invalide';
    return null;
  }

  /// Règle minimale exigée : 8 caractères, 1 majuscule, 1 chiffre.
  static bool isStrongPassword(String value) =>
      value.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(value) &&
      RegExp(r'[0-9]').hasMatch(value);

  static String? password(String? v) =>
      v == null || !isStrongPassword(v) ? 'Min. 8 car., 1 majuscule, 1 chiffre' : null;
}

enum PasswordStrength {
  vide('', 0, Colors.grey),
  faible('Faible', 0.25, Color(0xFFEF4444)),
  moyen('Moyen', 0.5, Colors.orange),
  bon('Bon', 0.75, Color(0xFF3B82F6)),
  fort('Fort', 1, Color(0xFF2ECC70));

  final String label;
  final double progression;
  final Color color;
  const PasswordStrength(this.label, this.progression, this.color);

  static PasswordStrength of(String value) {
    if (value.isEmpty) return vide;
    var score = 0;
    if (value.length >= 8) score++;
    if (value.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    if (!Validators.isStrongPassword(value)) return score >= 3 ? moyen : faible;
    if (score >= 5) return fort;
    if (score >= 4) return bon;
    return moyen;
  }
}
