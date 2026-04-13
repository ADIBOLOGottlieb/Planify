import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/objectif_provider.dart';
import '../../providers/alert_provider.dart';
import '../../providers/recurrence_provider.dart';
import '../../providers/compte_provider.dart';
import '../../utils/app_constants.dart';
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
  bool _showPwd = false;
  String? _error;

  bool _isStrongPassword(String value) {
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    return value.length >= 8 && hasUpper && hasNumber;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final err = await auth.inscrire(
      nom: _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      motDePasse: _pwdCtrl.text,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
    } else {
      await _loadData(auth);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen()), (r) => false);
    }
  }

  Future<void> _loadData(AuthProvider auth) async {
    final catProvider = context.read<CategoryProvider>();
    final txProvider = context.read<TransactionProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final objectifProvider = context.read<ObjectifProvider>();
    final alertProvider = context.read<AlertProvider>();
    final recurrenceProvider = context.read<RecurrenceProvider>();
    final compteProvider = context.read<CompteProvider>();
    final userId = auth.currentUser!.id;
    await catProvider.charger(userId);
    await compteProvider.charger(userId);
    await txProvider.charger(userId, catProvider);
    await budgetProvider.charger(userId, catProvider, txProvider);
    await objectifProvider.charger(userId);
    await alertProvider.charger(userId);
    await recurrenceProvider.charger(userId, catProvider);
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
                decoration: const BoxDecoration(color: Color(0xFFF5F7FA), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
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
                          validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null,
                        ),
                        const SizedBox(height: 16),
                      TextFormField(
                        controller: _pwdCtrl,
                        obscureText: !_showPwd,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(icon: Icon(_showPwd ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _showPwd = !_showPwd)),
                        ),
                        validator: (v) => v == null || !_isStrongPassword(v)
                            ? 'Min. 8 car., 1 majuscule, 1 chiffre'
                            : null,
                      ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPwdCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(labelText: 'Confirmer le mot de passe', prefixIcon: Icon(Icons.lock_outline)),
                          validator: (v) => v != _pwdCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
                        ),
                        const SizedBox(height: 28),
                        Consumer<AuthProvider>(
                          builder: (_, auth, __) => ElevatedButton(
                            onPressed: auth.isLoading ? null : _register,
                            child: auth.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("S'inscrire"),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Text('Déjà un compte ? Se connecter', style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.w500)),
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
