import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chargement_donnees.dart';
import '../../utils/app_constants.dart';
import '../../utils/validators.dart';
import '../../widgets/password_strength_indicator.dart';
import '../home/main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  final _reponseCtrl = TextEditingController();
  String _question = AuthViewModel.questionsSecretes.first;
  bool _showPwd = false;
  String? _error;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _reponseCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final auth = context.read<AuthViewModel>();
    final err = await auth.inscrire(
      nom: _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      motDePasse: _pwdCtrl.text,
      questionSecrete: _question,
      reponseSecrete: _reponseCtrl.text,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
    } else {
      final messenger = ScaffoldMessenger.of(context);
      final enLigne = await auth.modeEnLigne();
      if (!mounted) return;
      await chargerDonneesUtilisateur(context);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen()), (r) => false);
      if (enLigne) {
        messenger.showSnackBar(SnackBar(
          content: Text('Compte créé. Un email de vérification a été envoyé à ${auth.currentUser?.email}.'),
          duration: const Duration(seconds: 6),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                ],
              ),
            ),
            const Icon(Icons.account_balance_wallet_rounded, size: 52, color: Colors.white),
            const SizedBox(height: 8),
            const Text('Créer un compte', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: AppConstants.bgColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
                            child: Text(_error!, style: const TextStyle(color: Colors.red)),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _prenomCtrl,
                                decoration: const InputDecoration(labelText: 'Prénom'),
                                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _nomCtrl,
                                decoration: const InputDecoration(labelText: 'Nom'),
                                validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _pwdCtrl,
                          obscureText: !_showPwd,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(icon: Icon(_showPwd ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _showPwd = !_showPwd)),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: Validators.password,
                        ),
                        PasswordStrengthIndicator(password: _pwdCtrl.text),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPwdCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Confirmer le mot de passe', prefixIcon: Icon(Icons.lock_outline)),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: (v) => v != _pwdCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
                        ),
                        const SizedBox(height: 24),
                        const Text('Question de sécurité',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Elle servira à réinitialiser votre mot de passe en cas d\'oubli.',
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _question,
                          isExpanded: true,
                          items: AuthViewModel.questionsSecretes
                              .map((q) => DropdownMenuItem(value: q, child: Text(q, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => setState(() => _question = v!),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _reponseCtrl,
                          decoration: const InputDecoration(labelText: 'Votre réponse', prefixIcon: Icon(Icons.shield_outlined)),
                          validator: (v) => v == null || v.trim().length < 2 ? 'Réponse requise' : null,
                        ),
                        const SizedBox(height: 28),
                        Consumer<AuthViewModel>(
                          builder: (_, auth, __) => ElevatedButton(
                            onPressed: auth.isLoading ? null : _register,
                            child: auth.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("S'inscrire"),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text('Déjà un compte ? Se connecter', style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
