import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/objectif_provider.dart';
import '../providers/alert_provider.dart';
import '../providers/recurrence_provider.dart';
import '../providers/compte_provider.dart';
import 'auth/login_screen.dart';
import 'home/main_screen.dart';
import '../utils/app_constants.dart';
import 'onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
        CurvedAnimation(parent: _animController, curve: Curves.elasticOut));
    _animController.forward();
    _init();
  }

  Future<void> _init() async {
    final authProvider = context.read<AuthProvider>(); // capture before any await
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;
    if (!seen) {
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      return;
    }
    await authProvider.init();
    if (!mounted) return;
    if (authProvider.isLoggedIn) {
      await _loadData(authProvider);
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainScreen()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
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
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                          color: AppConstants.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.account_balance_wallet_rounded,
                        size: 55, color: AppConstants.primaryColor),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Planify',
                  style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gérez vos finances intelligemment',
                  style: TextStyle(
                      fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
                ),
                const SizedBox(height: 52),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(
                        Colors.white.withValues(alpha: 0.7)),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
