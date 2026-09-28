import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/chargement_donnees.dart';
import '../../utils/app_constants.dart';
import '../home/main_screen.dart';
import 'register_screen.dart';
import 'reset_password_dialog.dart';
import '../../utils/validators.dart';

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
  bool _resterConnecte = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _forgotPassword() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ResetPasswordDialog(),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Mot de passe réinitialisé. Vous pouvez vous connecter.'),
          backgroundColor: Colors.green));
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final auth = context.read<AuthViewModel>();
    final err = await auth.connecter(
        email: _emailCtrl.text.trim(),
        motDePasse: _pwdCtrl.text,
        resterConnecte: _resterConnecte);
    if (!mounted) return;
    if (err != null) {
      setState(() => _error = err);
    } else {
      await chargerDonneesUtilisateur(context);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainScreen()));
    }
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
                          decoration: BoxDecoration(
                            color: AppConstants.bgColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: Validators.email,
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
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _resterConnecte,
                                      activeColor: AppConstants.primaryColor,
                                      onChanged: (v) => setState(() => _resterConnecte = v ?? true),
                                    ),
                                    const Expanded(
                                      child: Text('Rester connecté'),
                                    ),
                                    TextButton(
                                      onPressed: _forgotPassword,
                                      child: const Text('Mot de passe oublié ?'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 28),
                                Consumer<AuthViewModel>(
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
                                      child: Text("S'inscrire", style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
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
