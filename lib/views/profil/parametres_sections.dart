import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/app_constants.dart';
import '../../viewmodels/preferences_viewmodel.dart';

/// Section « Notifications » des paramètres : alertes budgétaires, seuil
/// par défaut des nouveaux budgets et rappel quotidien de saisie.
class SectionNotifications extends StatelessWidget {
  const SectionNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesViewModel>();
    return _Carte(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.notifications_active_outlined),
          title: const Text('Alertes budgétaires'),
          subtitle: const Text('Seuil atteint et dépassement de budget'),
          value: prefs.alertesBudget,
          onChanged: prefs.setAlertesBudget,
        ),
        ListTile(
          leading: const Icon(Icons.percent_rounded),
          title: Text('Seuil d\'alerte par défaut : ${prefs.seuilParDefaut} %'),
          subtitle: Slider(
            value: prefs.seuilParDefaut.toDouble(),
            min: 50,
            max: 100,
            divisions: 10,
            label: '${prefs.seuilParDefaut} %',
            onChanged: (v) => prefs.setSeuilParDefaut(v.round()),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.alarm_rounded),
          title: const Text('Rappel quotidien de saisie'),
          subtitle: Text(prefs.rappelActif
              ? 'Chaque jour à ${prefs.heureRappel.format(context)}'
              : 'Désactivé'),
          value: prefs.rappelActif,
          onChanged: (v) => prefs.setRappel(actif: v),
        ),
        if (prefs.rappelActif)
          ListTile(
            leading: const SizedBox(width: 24),
            title: const Text('Heure du rappel'),
            trailing: Text(prefs.heureRappel.format(context),
                style: TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
            onTap: () async {
              final h = await showTimePicker(context: context, initialTime: prefs.heureRappel);
              if (h != null) await prefs.setRappel(actif: true, heure: h);
            },
          ),
      ],
    );
  }
}

/// Section « Apparence » : thème clair / sombre / système et couleur
/// d'accentuation.
class SectionApparence extends StatelessWidget {
  const SectionApparence({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<PreferencesViewModel>();
    return _Carte(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Clair')),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Sombre')),
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.phone_android_rounded), label: Text('Système')),
            ],
            selected: {prefs.themeMode},
            showSelectedIcon: false,
            onSelectionChanged: (s) => prefs.setThemeMode(s.first),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              const Text('Couleur d\'accent'),
              const Spacer(),
              for (final c in PreferencesViewModel.couleursAccent)
                GestureDetector(
                  onTap: () => prefs.setAccent(c),
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: prefs.accent.toARGB32() == c.toARGB32()
                            ? AppConstants.texteColor
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Carte extends StatelessWidget {
  final List<Widget> children;
  const _Carte({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: children),
      );
}
