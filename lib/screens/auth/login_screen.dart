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
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _showPwd = false;
  String? _error;

  bool _isStrongPassword(String value) {
    final hasUpper = RegExp(r'[A-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    return value.length >= 8 && hasUpper && hasNumber;
  }

  void _forgotPassword() {
    final emailCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mot de passe oublié'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: pwdCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              if (!_isStrongPassword(pwdCtrl.text.trim())) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Mot de passe faible'),
                    backgroundColor: Colors.red));
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              final authProvider = context.read<AuthProvider>();
              final err = await authProvider.reinitialiserMotDePasse(
                  email: emailCtrl.text.trim(), nouveau: pwdCtrl.text.trim());
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (err != null) {
                  messenger.showSnackBar(
                      SnackBar(content: Text(err), backgroundColor: Colors.red));
                } else {
                  messenger.showSnackBar(const SnackBar(
                      content: Text('Mot de passe réinitialisé'),
                      backgroundColor: Colors.green));
                }
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final auth = context.read<AuthProvider>();
    final err = await auth.connecter(email: _emailCtrl.text.trim(), motDePasse: _pwdCtrl.text);
    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
    } else {
      await _loadData(auth);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const Icon(Icons.account_balance_wallet_rounded, size: 64, color: Colors.white),
                      const SizedBox(height: 12),
                      const Text('Planify', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Text('Connexion', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 32),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                          ),
                          padding: const EdgeInsets.all(28),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 8),
                                Text('Bienvenue !', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                                const SizedBox(height: 4),
                                const Text('Connectez-vous pour gérer vos finances', style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 28),
                                if (_error != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
                                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                                  ),
                                if (_error != null) const SizedBox(height: 16),
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
                                  validator: (v) => v == null || v.length < 8 ? 'Min. 8 caractères' : null,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _forgotPassword,
                                    child: const Text('Mot de passe oublié ?'),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Consumer<AuthProvider>(
                                  builder: (_, auth, __) => ElevatedButton(
                                    onPressed: auth.isLoading ? null : _login,
                                    child: auth.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Se connecter'),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('Pas encore de compte ? '),
                                    GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                      child: const Text("S'inscrire", style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
