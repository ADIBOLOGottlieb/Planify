import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/validators.dart';
import '../../widgets/password_strength_indicator.dart';

enum _Mode { email, codeEmail, questionSecrete }

/// Réinitialisation du mot de passe en deux étapes :
/// 1. l'utilisateur saisit son email ;
/// 2. en ligne, il reçoit un code à 6 chiffres par email ; hors ligne, il
///    répond à sa question de sécurité. Il choisit ensuite un nouveau mot de
///    passe. Les mauvaises réponses comptent dans la limite de tentatives.
class ResetPasswordDialog extends StatefulWidget {
  const ResetPasswordDialog({super.key});

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _reponseCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  _Mode _mode = _Mode.email;
  String? _question;
  String? _info;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _reponseCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _etapeEmail(AuthViewModel auth) async {
    final err = await auth.demanderCodeReinitialisation(_emailCtrl.text);
    if (err == null) {
      _mode = _Mode.codeEmail;
      _info = 'Si un compte existe pour cet email, un code à 6 chiffres vient '
          'de vous être envoyé.';
      return;
    }
    if (err != AuthViewModel.horsLigne) {
      _error = err;
      return;
    }
    // Hors ligne : question de sécurité enregistrée sur l'appareil.
    final q = await auth.questionSecretePour(_emailCtrl.text);
    if (q == null) {
      _error = 'Réinitialisation impossible hors ligne : compte inconnu sur cet '
          'appareil ou sans question de sécurité.';
    } else {
      _mode = _Mode.questionSecrete;
      _question = q;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthViewModel>();
    setState(() {
      _loading = true;
      _error = null;
    });

    if (_mode == _Mode.email) {
      await _etapeEmail(auth);
      if (mounted) setState(() => _loading = false);
      return;
    }

    final err = _mode == _Mode.codeEmail
        ? await auth.reinitialiserAvecCode(
            email: _emailCtrl.text, code: _reponseCtrl.text.trim(), nouveau: _pwdCtrl.text)
        : await auth.reinitialiserMotDePasse(
            email: _emailCtrl.text, reponse: _reponseCtrl.text, nouveau: _pwdCtrl.text);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _loading = false;
        _error = err;
      });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final etape2 = _mode != _Mode.email;
    return AlertDialog(
      title: const Text('Mot de passe oublié'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailCtrl,
                enabled: !etape2,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: Validators.email,
              ),
              if (_info != null) ...[
                const SizedBox(height: 12),
                Text(_info!, style: const TextStyle(fontSize: 13)),
              ],
              if (etape2) ...[
                const SizedBox(height: 16),
                if (_mode == _Mode.questionSecrete)
                  Text(_question!, style: const TextStyle(fontWeight: FontWeight.w600)),
                TextFormField(
                  controller: _reponseCtrl,
                  keyboardType: _mode == _Mode.codeEmail
                      ? TextInputType.number
                      : TextInputType.text,
                  decoration: InputDecoration(
                      labelText: _mode == _Mode.codeEmail
                          ? 'Code reçu par email'
                          : 'Votre réponse'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requis';
                    if (_mode == _Mode.codeEmail && !RegExp(r'^\d{6}$').hasMatch(v.trim())) {
                      return 'Code à 6 chiffres';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _pwdCtrl,
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
                  validator: Validators.password,
                ),
                PasswordStrengthIndicator(password: _pwdCtrl.text),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
                  validator: (v) => v != _pwdCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
        TextButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(etape2 ? 'Réinitialiser' : 'Continuer'),
        ),
      ],
    );
  }
}
