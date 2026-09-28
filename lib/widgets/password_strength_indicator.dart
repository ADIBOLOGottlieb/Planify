import 'package:flutter/material.dart';

import '../utils/validators.dart';

/// Barre de force du mot de passe affichée sous le champ de saisie.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final s = PasswordStrength.of(password);
    if (s == PasswordStrength.vide) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: s.progression,
                minHeight: 6,
                color: s.color,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('Force : ${s.label}',
              style: TextStyle(color: s.color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
