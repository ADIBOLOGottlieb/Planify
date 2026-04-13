import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _slides = const [
    _OnboardSlide(
      lottie: 'assets/lottie/track.json',
      title: 'Suivez vos dépenses',
      subtitle: 'Enregistrez vos dépenses en temps réel et restez maître de vos finances.',
    ),
    _OnboardSlide(
      lottie: 'assets/lottie/budget.json',
      title: 'Planifiez votre budget',
      subtitle: 'Définissez des budgets par catégorie et recevez des alertes utiles.',
    ),
    _OnboardSlide(
      lottie: 'assets/lottie/insight.json',
      title: 'Visualisez vos finances',
      subtitle: 'Des graphiques clairs pour mieux comprendre vos habitudes.',
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _slides[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _index == i ? 22 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _index == i
                        ? AppConstants.primaryColor
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Passer'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      if (_index == _slides.length - 1) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(_index == _slides.length - 1
                        ? 'Commencer'
                        : 'Suivant'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardSlide extends StatelessWidget {
  final String lottie;
  final String title;
  final String subtitle;

  const _OnboardSlide(
      {required this.lottie, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            lottie,
            height: 220,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 220,
                alignment: Alignment.center,
                child: const Icon(Icons.warning_amber_rounded,
                    size: 80, color: Colors.amber),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(title,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
